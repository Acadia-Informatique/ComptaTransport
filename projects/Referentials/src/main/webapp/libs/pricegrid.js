"use strict";

/**************************
 * SHIPPING PRICING ENGINE
 **************************/
// Note : in this full-Javascript engine, the meaning of PricingSystem and PricingGrid
// is different from the database application. Each JS PricingGrid represent a single sheet
// in MS Excel, and a JS PricingSystem represents a collection of mutually dependent JS PricingGrids.
// For the database application, a whole JS PricingSystem represents only the JSON content
// of a PRICING_GRID_VERSION.


//TODO Proper JS module

/**
 * Typical policies, usable as calculation test cases or to model.
 *
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
			attribute: 150,
			price: 36.6
		}
	},
	{
		//TODO LEGACY, to be removed and replace with AggregatedPrice
		type: "DelegatedPrice",
		delegated_gridName: "B2B",
		delegated_additiveAmount: 3,
		delegated_additiveAmountType: "B2C" // optional, default to "MAIN"
	},

	{
		// first available "amountType" and "extra_info" are kept, drills deeper only for "amount"
		type: "AggregatedPrice",
		delegates:[
			{  // each delegate defines a "aX+b" linear amount, namely "factor * [delegated.amount] + amount"
				amountType : "MAIN", // optional, overrides delgated is set
				addAmount : 0, // optional, additive part (no delegated grid required)
				factor: 1, // optional, relies on delegated grid's amount
				delegated_gridName : "tarif_base", // name of another grid in the system
				extra_info : "" // optional, overrides delgated is set
			},
			{
				amountType : "TAX",
				factor: 0.195, //19.5% tax rate
				delegated_gridName : "tarif_base"
			},
			{
				amountType : "TAX"
				addAmount : 5, // 5€ fixed tax
			}
		]
	},

];
*/

/** When a PricingGrid.apply() returns one of these,
 * a PricingSystem.applyGrid() returns a list of them.
 */
class PricingResult {
	constructor(gridName, gridCell, amountType, amount, extra_info){
		this.gridName = gridName;
		this.gridCell = gridCell;
		this.amountType = amountType;
		this.amount = amount;
		this.extra_info = extra_info;
	}
}

class PricingSystem {
	constructor() {
		this.grids = [];
		//and plenty free space to add metadata !
	}

	clear(){
		this.grids.splice(0);
	}

	isEmpty(){
		return this.grids.length == 0;
	}

	static fromJSON(v) {
		let obj = new PricingSystem();
		obj.fromJSON(v);
		return obj;
	}

	/**
	 * Hydration.
	 * @param {*} v - JSON string or its parsed object
	 */
	fromJSON(v) {
		if (typeof v == "string") v = JSON.parse(v);

		for (const gridv of v.grids){
			let newGrid = PricingGrid.fromJSON(gridv);
			this.grids.push(newGrid);
		}
	}

	/**
	 * Create a pure data version, for serialization.
	 * Note : don't confuse with instance method clear() (which is related to isEmpty())
	 */
	static clean(systemObj) {
		let clone = JSON.parse(JSON.stringify(systemObj));

		for (const gridv of clone.grids){
			delete gridv["$$key"];
		}

		return clone;
	}



	/**
	 * Recursively propagates grid.apply() to the system, starting with specified grid.
	 * @param {*} gridName
	 * @param {*} pricedObject
	 * @see PricingGrid.apply()
	 * @returns returns a list of PricingResult instances (possibly a list of 0 or 1).
	 */
	applyGrid(gridName, pricedObject){
		let grid = this.findGridByName(gridName);
		if (grid) {
			let returnVal = grid.apply(pricedObject); //{gridCell, amount}
			let policy = returnVal?.gridCell?.policy;

			switch(policy?.type){
				case "DelegatedPrice":{// TODO legacy, to be removed
					let delegatedReturnVal = this.applyGrid(policy.delegated_gridName, pricedObject);
					delegatedReturnVal.push(returnVal);
					return delegatedReturnVal;
				} break;
				case "AggregatedPrice":{
					let aggregRes = [];
					for (let delegate of policy.delegates) {
						let amount = 0;
						let first_amountType = delegate.amountType;
						let first_extra_info = delegate.extra_info;
						if (delegate.factor){
							if (!delegate.gridName) throw new Error(`AggregatedPrice has a factor "${delegate.factor}" without a delegated grid to apply it ?!`);
							let delegateRes = this.applyGrid(delegate.gridName, pricedObject);
							let delegateFlatRes = PricingSystem.summarizeResult(delegateRes);
							amount += delegate.factor * delegateFlatRes.total();
							if (!first_amountType) first_amountType = delegateFlatRes.amountType;
							if (!first_extra_info) first_extra_info = delegateFlatRes.extra_info;
						}
						if (delegated.addAmount){
							amount += delegate.addAmount;
						}
						aggregRes.push(new PricingResult(gridName, gridCell, first_amountType, amount, first_extra_info));
					}
					return aggregRes;
				} break;
				default: { // standard case
					return [returnVal];
				}
			}
		} else {
			throw new Error(`Grid "${gridName}" not found in system.`);
		}
	}


	/**
	 * Make a flat total.
	 * @argument resultList - result of applyGrid
	 */
	static summarizeResult(resultList){

		let flatResult = {
			total(){
				let s = 0;
				for (let key of Object.keys(this)){
					switch(key){
						// sorry for Q&D, i'd like to nest the amounts deeper but i have some VueJS reactivity issues
						case "amountType":
						case "extra_info":
						case "total":
							continue;
						default: {
							let amountType = key;
							s += this[amountType];
						}
					}
				}
				return s;
			}
		};

		for (let res of resultList){
			// 1) handle amount
			if (res.amount === null){
				// leave unchanged
			} else if (isNaN(res.amount)){
				flatResult[res.amountType] = NaN; // a single NaN in the chain destroys the total
			} else {
				if (!flatResult[res.amountType]) flatResult[res.amountType] = 0;
				flatResult[res.amountType] += res.amount;
			}
			// 2) handle non-cascading data collection (1st available is kept and deeper ones are discarded)
			if (!flatResult.amountType) flatResult.amountType = res.amountType;
			if (!flatResult.extra_info) flatResult.extra_info = res.extra_info;
		}
		return flatResult;
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
					throw new Error(`"${grid.name}"${JSON.stringify(cell.coords)} -> "${name}"`);
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
		delete(v.$$key);
		let obj = new PricingGrid(v.name);
		Object.assign(obj, v);
		return obj;
	}

	/**
	 * Run the pricing engine, to return the computed amount (and how it finds it)
	 * @param {*} pricedObject - expected to provide a getPPGRawCoordinates() method, returning a raw 'coordinates' Object"
	 * @returns returns a PricingResult instance. If something goes wrong, "gridCell" can be null or empty, and "amount" may be NaN.
	 */
	apply(pricedObject){
		let gridCell = this._findGridCellFor(pricedObject);
		if (gridCell == null || gridCell.policy == null){
			return new PricingResult(this.name, gridCell, null, NaN, null);
		} else {
			let policy = gridCell.policy;
			let amountType = policy.amountType;
			let extra_info = policy.extra_info;

			let amount = null;
			switch(policy.type){ // try with POLYMORPHISM ;-)
				case "FixedPrice": {
					amount = policy.price;
				} break;
				case "PerVolumePrice": {
					let offset = policy.offset ?? {attribute: 0, price: 0};
					let volume = pricedObject[policy.attribute] - offset.attribute;
					if (volume >= 0) {
						if (policy.rounding) {
							let roundedVolume = policy.rounding * Math.ceil(volume / policy.rounding);
							amount = roundedVolume * policy.price + offset.price;
						} else {
							amount = volume * policy.price + offset.price;
						}
					} else {// better not support negative offsetting...
						amount = NaN;
					}
				} break;
				case "DelegatedPrice": { // TODO legacy, to be removed
					amountType =  policy.delegated_additiveAmountType;
					amount = policy.delegated_additiveAmount;
				} break;
				default : {
					throw new Error("Unsupported type of Pricing Policy : " + policy.type);
				}
			}
			if (!amountType) amountType = "MAIN";
			return new PricingResult(this.name, gridCell, amountType, amount, extra_info);
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
				console.warn("Overlapping cell definition !", applicableCells);
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
					let comparison = dimension.comparison ?? "eqSup"; // retro-compatibility
					for (const category of dimension.categories){
						if ((comparison == "eqSup" && rawValue >= category.value)
						  || (comparison == "strictSup" && rawValue > category.value)){
							categoryValue = category.value;
							// keep last fitting category
						} else {
							break; // Warning : quick break possible only when categories are ascendingly sorted !
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
				case "DirectCategory": {
					categoryValue = rawValue; // check if among dimension.categories ?... maybe when we support wildcard.
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
				defaultDimension = {type, name, raw_name:"", categories:[{value: 0}], comparison:"eqSup" };
				break;
			case "DirectCategory":
				defaultDimension = {type, name, raw_name:"", categories:[{value: "All"}] };
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

function test(){
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
					{value: 0}, {value: 10}, {value: 100}
				]
			},
			{
				name: "zone",
				raw_name: "departement",
				type: "EnumCategory",
				categories : [
					{value: "Zone 01", enum:["75","77","78","91","92","93","94","95","02","08","10","14","18","27","28","36","37","41","45","51","58","59","60","61","62","72","76","80","89"]},
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
				coords: {wcat:10, zone:"Zone 01"},
				policy: {
					type: "FixedPrice",
					price: 10.9
				}
			},
			{
				coords: {wcat:10, zone:"Corse"},
				policy: {
					type: "FixedPrice",
					price: 10.9 + 35
				}
			},
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
}
