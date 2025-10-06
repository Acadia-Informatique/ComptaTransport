"use strict";

//TODO Proper JS module

/**
 * Typical policies, usable as calculation test cases or to model.
 */
const POLICY_PROTOTYPES = [
	{
		type: "FixedPrice",
		price: 11.9
	},
	{
		type: "PerVolumePrice",
		attribute: "weight",
		rounding: 10,
		price: 4.4,
		offset : {
			attribute: 0,
			price: 0
		}
	},
	{
		type: "DelegatedPrice",
		delegated_gridName: "B2B",
		delegated_additiveAmount: 3
	},
];



class PricingSystem {
	constructor(name) {
		this.name = name;
		this.grids = [];
	}

	/**
	 * Hydration.
	 * @param {*} v - JSON string or its parsed object
	 */
	static fromJSON(v) {
		if (typeof v == "string") v = JSON.parse(v);
		let obj = new PricingSystem(v.name);

		for (const gridv of v.grids){
			let newGrid = PricingGrid.fromJSON(gridv);
			obj.grids.push(newGrid);
		}

		return obj;
	}


	/**
	 * Recursively propagates grid.apply() to the system, starting with specified grid.
	 * @param {*} gridName
	 * @param {*} pricedObject
	 * @see PricingGrid.apply()
	 * @returns same as PricingGrid.apply(), plus "gridName" and optional "nested" (chaining)
	 */
	applyGrid(gridName, pricedObject){
		let grid = this.findGridByName(gridName);
		if (grid) {

			let returnVal = grid.apply(pricedObject); //{gridCell, amount}
			let policy = returnVal?.gridCell?.policy;
			if (policy?.type == "DelegatedPrice"){
				let nestedReturnVal = this.applyGrid(policy.delegated_gridName, pricedObject);
				return {
					gridName,
					gridCell:returnVal.gridCell,
					amount: nestedReturnVal.amount + policy.delegated_additiveAmount,
					nested: nestedReturnVal //<- chaining extension to grid.apply()'s return
				};
			} else {
				return {
					gridName,
					...returnVal
				}
			}

		} else {
			throw new Error(`Grid "${gridName}" not found in system "${this.name}".`);
		}
	}

	//---- Grid CRUD
	findGridByName(name) {
		return this.grids.find(g => g.name == name);
	}

	/**
	 * Create new GRid in system.
	 * @param {*} name - must be non empty and unique (arg is NOT checked)
	 * @returns created grid
	 */
	addNewGrid(name){
		let newGrid = new PricingGrid(name);
		newGrid.updateCellsFromDimensions();
		this.grids.push(newGrid);
	}

	/**
	 * Deletes a grid by name, if it exists AND is free of internal references.
	 *
	 * @param {*} name
	 * @returns the removed grid
	 * @throw Error when internal reference exist to target (eg. by a DelegatedPrice)
	 */
	removeGrid(name){
		for (const grid of this.grids){
			for (const cell of grid.gridCells){
				if (cell?.policy?.delegated_gridName == name){
					throw new Error(`Grid "${name}" cannot be removed, for it is referenced by cell ${JSON.stringify(cell.coords)} of grid "${grid.name}".`);
				}
			}
		}

		let removedGridIdx = this.grids.findIndex(g => g.name == name);
		if (removedGridIdx >=0){
			return this.grids.splice(removedGridIdx, 1)[0]; // supposedly no dupes
		} else {
			return null;
		}
	}

	/**
	 * Rename a grid and updates all internal references.
	 * @param oldName
	 * @param newName
	 */
	renameGrid(oldName, newName){
		for (const grid of this.grids){
			for (const cell of grid.gridCells){
				if (cell?.policy?.delegated_gridName == oldName){
					cell.policy.delegated_gridName = newName;
				}
			}
		}
		this.findGridByName(oldName).name = newName;
	}
}

class PricingGrid {
	static #keySeq = 0;
	constructor(name){
		this.$$key = PricingGrid.#keySeq++; //for VueJS animation only, meaningless value
		this.name = name;
		this.dimensions = [];
		this.gridCells = [];
	}

	/**
	 * Hydration.
	 * @param {*} v - JSON string or its parsed object
	 */
	static fromJSON(v) {
		if (typeof v == "string") v = JSON.parse(v);
		let obj = new PricingGrid(v.name);
		Object.assign(obj, v);
		return obj;
	}

	/**
	 * Run the pricing engine, to return the computed amount (and how it finds it)
	 * @param {*} pricedObject - expected to provide a getPPGRawCoordinates() method, returning a raw 'coordinates' Object"
	 * @returns returns {gridCell, amount}. If something goes wrong, "gridCell" can be null or empty, and "amount" may be NaN.
	 */
	apply(pricedObject){
		let gridCell = this._findGridCellFor(pricedObject);
		if (gridCell == null || gridCell.policy == null){
			return {gridCell, amount:NaN}; //or throw ?..
		} else {
			let policy = gridCell.policy;
			let amount = null;
			switch(policy.type){ // try with POLYMORPHISM ;-)
				case "FixedPrice": {
					amount = policy.price;
				} break;
				case "PerVolumePrice": {
					let offset = policy.offset ?? {attribute: 0, price: 0};
					let volume = pricedObject[policy.attribute] - offset.attribute;
					if (volume >= 0) {
						let roundedVolume = policy.rounding * Math.ceil(volume / policy.rounding);
						amount = roundedVolume * policy.price + offset.price;
					} else {// better not support negative offsetting...
						amount = NaN;
					}
				} break;
				case "DelegatedPrice": {
					amount = null; /* = will have to be resolved at PricingSystem level */
				} break;
				default : {
					throw new Error("Unsupported type of Pricing Policy : " + policy.type);
				}
			}
			return {gridCell, amount};// <- important structure !
		}
	}

	_findGridCellFor(pricedObject){
		let rawCoordinates = pricedObject.getPPGRawCoordinates();
		let gridCoordinates = this._toGridCoordinates(rawCoordinates);

		return this.getCellAt(gridCoordinates);
	}

	getCellAt(gridCoordinates){
		// collect all applicable grid cells...
		let applicableCells = [];
		for (const cell of this.gridCells){
			if (this._matchCoords(gridCoordinates, cell.coords)){
				applicableCells.push(cell);
			}
		}

		switch(applicableCells.length){
			case 0: {
				console.debug("No cell found");
				return null;
			}
			case 1: {
				return applicableCells.pop();
			}
			default: {
				console.warn(applicableCells);
				throw new Error("Overlapping cell definition !");
			}
		}
	}

	ensureCellAt(gridCoordinates){
		let cell = this.getCellAt(gridCoordinates);
		if (!cell){
			cell = {coords: gridCoordinates, policy: null};
			this.gridCells.push(cell);
		}
		return cell;
	}

	//translate raw coordinates to grid coordinates (= apply category definitions)
	_toGridCoordinates(rawCoordinates){
		let gridCoordinates = {};
		for (const dimension of this.dimensions) {
			let rawValue = rawCoordinates[dimension.raw_name];
			let categoryValue = null;
			switch(dimension.type){
				case "ThresholdCategory": {
					for (const category of dimension.categories){
						if (rawValue >= category.value){
							categoryValue = category.value;
							// keep last fitting category
						}
					}

				} break;
				case "EnumCategory": {
					for (const category of dimension.categories){
						if (category.enum.includes(rawValue)){
							categoryValue = category.value;
							break; // pick 1st matching category
						}
					}
				} break;
				default: {
				} break;
			}
			gridCoordinates[dimension.name] = categoryValue;
		}
		return gridCoordinates;
	}

	/** Returns true for a match.
	 * Important note : comparison is done *only* when a property is defined on both side,
	 * so "loose" matching is possible.
	 */
	_matchCoords(searchedCoords, gridCoords){
		let isMatching = true;
		for (const coordName in searchedCoords){
			if (coordName in gridCoords && gridCoords[coordName] != searchedCoords[coordName]){
				isMatching = false;
			}
		}
		return isMatching;
	}


	//---- Dimension CRUD

	findDimensionByName(name){
		return this.dimensions.find(d => d.name == name)
	}

	/**
	 * append a new default dimension to the grid.
	 * @param type among "ThresholdCategory", "EnumCategory", etc.
	 * @returns created dimension
	 */
	addNewDimension(type){
		// find a non-used name
		let name = "x";
		while (this.findDimensionByName(name)){ name += "x"; }

		// TODO move defaulting for each type somewhere else
		let defaultDimension;
		switch(type){
			case "EnumCategory":
				defaultDimension = {type, name, raw_name:"", categories:[{value: "All", enum: []}] };
				break;
			case "ThresholdCategory":
				defaultDimension = {type, name, raw_name:"", categories:[{value: 0}] };
				break;
			default:
				throw new Error("Unsupported type of Dimension : " + type);
		}

		// readjust existing grid cells
		// => all existing cells goe to 1st category of new dimension
		let defaultCategoryVal = defaultDimension.categories[0].value;
		for (const cell of this.gridCells){
			cell.coords[name] = defaultCategoryVal
		}

		// finally, add dimension
		this.dimensions.push(defaultDimension);
		return defaultDimension;
	}

	/**
	 * Remove a dimension from the grid, by index.
	 */
	removeDimension(removedDimIdx){
		let removedDimension = this.dimensions[removedDimIdx];

		// readjust existing grid cells
		// => keep cells matching the 1st category in removed dimension
		let remainingDimensions = this.dimensions.filter( (dim, idx) => idx != removedDimIdx);
		let remainingKeys = PricingGrid.getAllAvailableCoords(remainingDimensions);
		let newGridCells = [];
		for (const coords of remainingKeys){
			let coordsPlus = {[removedDimension.name]: removedDimension.categories[0].value, ...coords};

			let policy = null;
			let oldCell = this.getCellAt(coordsPlus);
			if (oldCell) policy = oldCell.policy;

			let newCell = {coords, policy};
			newGridCells.push(newCell);
		}
		this.gridCells = newGridCells;

		// finally, remove dimension
		this.dimensions.splice(removedDimIdx, 1);
	}

	/**
	 * Rename a dimension.
	 * @param oldName
	 * @param newName
	 */
	renameDimension(oldName, newName){
		let oldNamedDim = this.findDimensionByName(oldName);
		let newNamedDim = this.findDimensionByName(newName);
		if (!oldNamedDim) throw new Error("Cannot rename dimension, name not found : " + oldName);
		if (newNamedDim) throw new Error("Cannot rename dimension, new name already used : " + newName);

		oldNamedDim.name = newName;

		this.gridCells.forEach(cell => {
			cell.coords[newName] = cell.coords[oldName];
			delete cell.coords[oldName];
		});
	}


	static getAllAvailableCoords(dimensions){
		let coords = [{}];
		for (const dim of dimensions){
			let newCoords = [];
			for (const cat of dim.categories){
				for (const c of coords){
					newCoords.push({[dim.name]: cat.value, ...c});
				}
			}
			coords = newCoords;
		}
		return coords;
	}


	updateCellsFromDimensions() {
		let newGridCells = [];
		for (const coords of PricingGrid.getAllAvailableCoords(this.dimensions)){
			let cell = this.getCellAt(coords);
			let policy = cell?.policy ?? null;
			newGridCells.push({coords, policy});
		}

		this.gridCells = newGridCells;
	}
}


//===============================



const theSystem = new PricingSystem("ACADIA");

let pricingGrid_acadia_b2b = new PricingGrid("ACA-BTB");
theSystem.grids.push(pricingGrid_acadia_b2b);

pricingGrid_acadia_b2b.dimensions =
	[
		{
			name: "wcat",
			raw_name : "poids",
			type: "ThresholdCategory",
			categories : [
				{value: 0},
				{value: 5},
				{value: 7},
				{value: 9},
				{value: 12},
				{value: 15},
				{value: 20},
				{value: 25},
				{value: 30},
				{value: 40},
				{value: 45},
				{value: 50},
				{value: 55},
				{value: 60},
				{value: 70},
				{value: 80},
				{value: 90},
				{value: 100}
			]
		},
		{
			name: "zone",
			raw_name: "departement",
			type: "EnumCategory",
			categories : [
				{value: "Zone 01", enum:["75","77","78","91","92","93","94","95","02","08","10","14","18","27","28","36","37","41","45","51","58","59","60","61","62","72","76","80","89"]},
				{value: "Zone 02", enum:["01","03","07","15","21","23","24","26","29","35","39","42","43","44","47","48","49","50","52","53","54","55","63","69","70","71","86","87","88"]},
				{value: "Zone 03", enum:["16","17","19","22","25","33","38","56","57","67","68","73","74","79","85","90"]},
				{value: "Zone 04", enum:["06","09","11","12","13","30","31","32","34","40","46","64","66","81","82","84"]},
				{value: "Zone 05", enum:["04","05","65","83","98"]},
				{value: "Corse",   enum:["20"]},
			]
		},
	]
;

pricingGrid_acadia_b2b.gridCells =
	[
		{
			coords: {wcat:0, zone:"Zone 01"},
			policy: {
				type: "FixedPrice",
				price: 9.9
			}
		},
		{
			coords: {wcat:0, zone:"Corse"},
			policy: {
				type: "FixedPrice",
				price: 9.9 + 35
			}
		},
		{
			coords: {wcat:5, zone:"Zone 01"},
			policy: {
				type: "FixedPrice",
				price: 10.9
			}
		},
		{
			coords: {wcat:5, zone:"Corse"},
			policy: {
				type: "FixedPrice",
				price: 10.9 + 35
			}
		},

		{coords: {wcat:7, zone:"Zone 01"}, policy: {type: "FixedPrice",
				price: 11.9}},
		{coords: {wcat:7, zone:"Corse"}, policy: {type: "FixedPrice",
				price: 11.9 + 35}},

		{coords: {wcat:9, zone:"Zone 01"}, policy: {type: "FixedPrice",
				price: 13.9}},
		{coords: {wcat:9, zone:"Corse"}, policy: {type: "FixedPrice",
				price: 13.9 + 35}},

		{coords: {wcat:12, zone:"Zone 01"}, policy: {type: "FixedPrice",
				price: 14.9}},
		{coords: {wcat:12, zone:"Corse"}, policy: {type: "FixedPrice",
				price: 14.9 + 35}},

		{coords: {wcat:15, zone:"Zone 01"}, policy: {type: "FixedPrice",
				price: 18.9}},
		{coords: {wcat:15, zone:"Corse"}, policy: {type: "FixedPrice",
				price: 18.9 + 35}},

		{coords: {wcat:20, zone:"Zone 01"}, policy: {type: "FixedPrice",
				price: 23.9}},
		{coords: {wcat:20, zone:"Corse"}, policy: {type: "FixedPrice",
				price: 23.9 + 35}},

		{coords: {wcat:25, zone:"Zone 01"}, policy: {type: "FixedPrice",
				price: 27.9}},
		{coords: {wcat:25, zone:"Corse"}, policy: {type: "FixedPrice",
				price: 27.9 + 35}},

		{coords: {wcat:30, zone:"Zone 01"}, policy: {type: "FixedPrice",
				price: 29.9}},
		{coords: {wcat:30, zone:"Corse"}, policy: {type: "FixedPrice",
				price: 29.9 + 35}},

		{coords: {wcat:40, zone:"Zone 01"}, policy: {type: "FixedPrice",
				price: 34.9}},
		{coords: {wcat:40, zone:"Corse"}, policy: {type: "FixedPrice",
				price: 34.9 + 35}},

		{coords: {wcat:45, zone:"Zone 01"}, policy: {type: "FixedPrice",
				price: 36.9}},
		{coords: {wcat:45, zone:"Corse"}, policy: {type: "FixedPrice",
				price: 36.9 + 35}},

		{coords: {wcat:50, zone:"Zone 01"}, policy: {type: "FixedPrice",
				price: 40.9}},
		{coords: {wcat:50, zone:"Corse"}, policy: {type: "FixedPrice",
				price: 40.9 + 35}},

		{coords: {wcat:55, zone:"Zone 01"}, policy: {type: "FixedPrice",
				price: 42.9}},
		{coords: {wcat:55, zone:"Corse"}, policy: {type: "FixedPrice",
				price: 42.9 + 35}},

		{coords: {wcat:60, zone:"Zone 01"}, policy: {type: "FixedPrice",
				price: 44.9}},
		{coords: {wcat:60, zone:"Corse"}, policy: {type: "FixedPrice",
				price: 44.9 + 35}},

		{coords: {wcat:70, zone:"Zone 01"}, policy: {type: "FixedPrice",
				price: 46.9}},
		{coords: {wcat:70, zone:"Corse"}, policy: {type: "FixedPrice",
				price: 46.9 + 35}},

		{coords: {wcat:80, zone:"Zone 01"}, policy: {type: "FixedPrice",
				price: 49.9}},
		{coords: {wcat:80, zone:"Corse"}, policy: {type: "FixedPrice",
				price: 49.9 + 35}},

		{coords: {wcat:90, zone:"Zone 01"}, policy: {type: "FixedPrice",
				price: 54.9}},
		{coords: {wcat:90, zone:"Corse"}, policy: {type: "FixedPrice",
				price: 54.9 + 35}},





		{
			coords: {wcat:100, zone:"Zone 01"},
			policy: {
				type: "PerVolumePrice",
				attribute: "poids",
				rounding: 10,
				price: 3.6
			}
		},
		{
			coords: {wcat:100, zone:"Corse"},
			policy: {
				type: "PerVolumePrice",
				attribute: "poids",
				rounding: 10,
				price: 5
			}
		}

	]
;



let pricingGrid_acadia_b2c = new PricingGrid("ACA-BTC");
theSystem.grids.push(pricingGrid_acadia_b2c);


pricingGrid_acadia_b2c.dimensions =
	[
		{
			name: "wcat",
			raw_name : "poidsEntier",
			type: "ThresholdCategory",
			categories : [
				{value: 0},
				{value: 5},
				{value: 8},
				{value: 11},
				{value: 15},
				{value: 20},
				{value: 25},
				{value: 30},
				{value: 40},
				{value: 45},
				{value: 50},
				{value: 100},
			]
		}
	]
;

pricingGrid_acadia_b2c.gridCells =
	[
		{
			coords: {wcat:0},
			policy: {
				type: "FixedPrice",
				price: 13.9
			}
		},
		{
			coords: {wcat:5},
			policy: {
				type: "FixedPrice",
				price: 15.9
			}
		},
		{
			coords: {wcat:8},
			policy: {
				type: "FixedPrice",
				price: 18.9
			}
		},
		{
			coords: {wcat:11},
			policy: {
				type: "FixedPrice",
				price: 20.9
			}
		},

		{coords: {wcat:15}, policy: {type: "FixedPrice", price: 23.9}},
		{coords: {wcat:20}, policy: {type: "FixedPrice", price: 26.9}},
		{coords: {wcat:25}, policy: {type: "FixedPrice", price: 30.9}},
		{coords: {wcat:30}, policy: {type: "FixedPrice", price: 32.9}},
		{coords: {wcat:40}, policy: {type: "FixedPrice", price: 37.9}},
		{coords: {wcat:45}, policy: {type: "FixedPrice", price: 39.9}},

		{
			coords: {wcat:50},
			policy: {
				type: "DelegatedPrice",
				delegated_gridName: "ACA-BTB",
				delegated_additiveAmount: 10
			}
		},
		{
			coords: {wcat:100},
			policy: {
				type: "DelegatedPrice",
				delegated_gridName: "ACA-BTB",
				delegated_additiveAmount: 20
			}
		}

	]
;


var uneCommande = new class {
	constructor(poids, codePostal){
		this.poids = poids;
		this.codePostal = codePostal;
	}

	getPPGRawCoordinates(){
		let departement = this.codePostal.substring(0,2);
		return {
			poids : this.poids,
			poidsEntier: Math.ceil(this.poids),
			departement,
		};
	}
}(45 /*kg*/, "93420");

let xxx = theSystem.applyGrid("ACA-BTB", uneCommande);
console.log(xxx);