"use strict";

class CommandeALivrer {
	constructor(numero, poids, codePostal){
		this.numero = numero;
		this.poids = poids;
		this.codePostal = codePostal;
	}

	// from interface "pricedObject" : return common Pricing Policy Grid raw coordinates as object
	getPPGRawCoordinates(){
		let dptStr = this.codePostal ? this.codePostal.substring(0,2) : "-1";
		let departement = parseInt(dptStr, 10);
		return {
			poidsEntier: Math.ceil(this.poids),
			departement: departement
		};
	}
}

/*
class Dimension {
	constructor(name) {
		this.name = name;
	}
}

class CategoryDimension extends Dimension {
	constructor(name, categories) {
		super(name);
		this.categories = categories;
	}
}
/*
class ThresholdCategoryDimension extends CategoryDimension {
	constructor(name, thresholds) {
		super(name);
		this.thresholds = thresholds;
	}
} TODO sur les categories[i], trier et générer en auto les *.value en fonction des *.threshold

class EnumCategoryDimension extends CategoryDimension {
	constructor(name, thresholds) {
		super(name);
		this.thresholds = thresholds;
	}
}

// TODO ajouter système de délégation de grille dans les Policy (avec report de frais, ex. BTC en poids élevé = BTB + 3,10 ou 20 €)

class PricingPolicy {

}
*/

// TODO serialize / hydration for all GridStystem participants... use only rehydration constructors ?!

class PricingSystem {
	constructor(jsonStr) {
		this.grids = [];
		if (jsonStr) {
			//TODO hydration
		}
	}

	findGridByName(name) {
		return this.grids.find(g => g.name == name);
	}
}

class PricingGrid {
	constructor(name){
		this.name = name;
		this.dimensions = [];
		this.gridCells = [];
	}


	/**
	 * Returns policy and computed amount
	 * TODO assess usability (maybe keep policy and application separated)
	*/
	apply(pricedObject){
		let gridCell = this._findGridCellFor(pricedObject);
		if (gridCell == null){
			return "NOT SUPPORTED";
		} else {
			let policy = gridCell.policy;
			let amount = null;
			switch(policy.type){
				case "FixedPrice": {
					amount = policy.price;
				} break;
				case "PerVolumePrice": {
					let volume = pricedObject[policy.dimension];
					console.warn(volume, pricedObject);
					let roundedVolume = policy.rounding * Math.ceil(volume / policy.rounding);
					amount = roundedVolume * policy.price;
				} break;
				default : {
					throw new Error("Unsupported type of Pricing Policy : " + policy.type);
				}
			}
			return {gridCell, amount};
		}
	}

	_findGridCellFor(pricedObject){
		let rawCoordinates = pricedObject.getPPGRawCoordinates();
		let gridCoordinates = this._toGridCoordinates(rawCoordinates);

		return this.gridCellAt(gridCoordinates);
	}

	gridCellAt(gridCoordinates){
		// collect all applicable grid cells...
		let applicablePolicies = [];
		for (let cell of this.gridCells){
			if (this._matchCoords(gridCoordinates, cell.coords)){
				applicablePolicies.push(cell);
			}
		}

		switch(applicablePolicies.length){
			case 0: {
				console.log("No policy found");
				return null;
			}
			case 1: {
				return applicablePolicies.pop();
			}
			default: {
				console.warn(applicablePolicies);

				throw new Error("Overlapping policy definition !");
			}
		}
	}

	//translate raw coordinates to grid coordinates (= apply category definitions)
	_toGridCoordinates(rawCoordinates){
		let gridCoordinates = {};
		for (let dimension of this.dimensions) {
			let rawValue = rawCoordinates[dimension.raw_name];
			let categoryValue = null;
			switch(dimension.type){
				case "ThresholdCategory": {
					for (let category of dimension.categories){
						if (rawValue >= category.threshold){
							categoryValue = category.value;
							// keep last fitting category
						}
					}

				} break;
				case "EnumCategory": {
					for (let category of dimension.categories){
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

	// Returns true for a match.
	// Important note : an item is matching a grid cell even when the grid cell is "loosely defined".
	_matchCoords(searchedCoords, gridCoords){
		let isMatching = true;
		for (let coordName in searchedCoords){
			if (coordName in gridCoords){
				if (gridCoords[coordName] != searchedCoords[coordName])
					isMatching = false;
			}
		}
		return isMatching;
	}

	/**
	 * append a new default dimension to the grid
	 */
	addNewDimension(){
		let name = "dim"; // default name
		let type = "EnumCategory"; // default type

		// find a non-used name
		while (this.dimensions.find( dim => dim.name == name)){ name += "*"; }

		// TODO move defaulting for each type somewhere else
		let defaultDimension;
		switch(type){
			case "EnumCategory":
				defaultDimension = {name, raw_name:"", categories:[{value: "All", enum: []}] };
				break;
			case "ThresholdCategory":
				defaultDimension = {name, raw_name:"", categories:[{value: "All", threshold: 0}] };
				break;
			default:
				throw new Error("Unsupported type of Dimension : " + type);
		}

		// readjust existing grid cells
		// => all existing cells goe to 1st category of new dimension
		let defaultCategoryVal = defaultDimension.categories[0].value;
		for (let cell of this.gridCells){
			cell.coords[name] = defaultCategoryVal
		}

		// finally, add dimension
		this.dimensions.push(defaultDimension);
	}

	/**
	 * Remove a named dimension from the grid
	 */
	removeDimension(name){
		let removedDimIdx = this.dimensions.findIndex( dim => dim.name == name);
		if (removedDimIdx == -1) throw new Error("No such dimension : " + name);
		let removedDimension = this.dimensions[removedDimIdx];

		// readjust existing grid cells
		// => keep cells matching the 1st category in removed dimension
		let remainingDimensions = this.dimensions.filter( (dim, idx) => idx != removedDimIdx);

		function collectRemainingKeys(dimensions, keyVal){
			if (dimensions.length == 0){
				return [ {[keyVal.k]: keyVal.v} ];
			} else {
				let childDim = dimensions[0];
				let results = [];
				for (let childCat of childDim.categories){
					let childResults = collectRemainingKeys(dimensions.slice(1), {k:childDim.name, v:childCat.value});
					for (let cr of childResults){
						if (keyVal != null) {
							let obj = { [keyVal.k]: keyVal.v, ...cr};
							results.push(obj);
						} else{
							results.push(cr);
						}
					}
				}
				return results;
			}
		}
		let remainingKeys = collectRemainingKeys(remainingDimensions, null);
		let newGridCells = [];
		for (let coords of remainingKeys){
			let coordsPlus = {[removedDimension.name]: removedDimension.categories[0].value, ...coords};

			let policy = null;
			let oldCell = this.gridCellAt(coordsPlus);
			if (oldCell) policy = oldCell.policy;

			let newCell = {coords, policy};
			newGridCells.push(newCell);
		}
		this.gridCells = newGridCells;

		// finally, remove dimension
		this.dimensions.splice(removedDimIdx, 1);
	}
}


//===============================



const theSystem = new PricingSystem();

let pricingGrid_acadia_b2b = new PricingGrid("ACA-BTB");
theSystem.grids.push(pricingGrid_acadia_b2b);

pricingGrid_acadia_b2b.dimensions =
	[
		{
			name: "wcat",
			raw_name : "poidsEntier",
			type: "ThresholdCategory",
			categories : [
				{value: "0-5 kg", threshold: 0},
				{value: "5-100 kg", threshold: 5},
				{value: "100+ kg", threshold: 100}
			]
		},
		{
			name: "zone",
			raw_name: "departement",
			type: "EnumCategory",
			categories : [
				{value: "A", enum: [77,75]},
				{value: "B", enum: [93]},
				{value: "Corse", enum: [20]},
			]
		},
	]
;

pricingGrid_acadia_b2b.gridCells =
	[
		{
			coords: {wcat:"0-5 kg", zone:"A"},
			policy: {
				type: "FixedPrice",
				price: 9.9
			}
		},
		{
			coords: {wcat:"0-5 kg", zone:"B"},
			policy: {
				type: "FixedPrice",
				price: 10.9
			}
		},
		{
			coords: {wcat:"0-5 kg", zone:"Corse"},
			policy: {
				type: "FixedPrice",
				price: 99.9
			}
		},
		{
			coords: {wcat:"5-100 kg", zone:"A"},
			policy: {
				type: "FixedPrice",
				price: 54.9
			}
		},
		{
			coords: {wcat:"5-100 kg", zone:"B"},
			policy: {
				type: "FixedPrice",
				price: 55.9
			}
		},
		{
			coords: {wcat:"5-100 kg", zone:"Corse"},
			policy: {
				type: "FixedPrice",
				price: 549.9
			}
		},
		{
			coords: {wcat:"100+ kg", zone:"A"},
			policy: {
				type: "PerVolumePrice",
				dimension: "poids",
				rounding: 10,
				price: 4.4
			}
		},
		{
			coords: {wcat:"100+ kg", zone:"B"},
			policy: {
				type: "PerVolumePrice",
				dimension: "poids",
				rounding: 10,
				price: 4.7
			}
		},
		/*{
			coords: {wcat:"100+ kg", zone:"Corse"},
			on fait pas
		}
		*/
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
				{value: "0-5 kg", threshold: 0},
				{value: "5-8 kg", threshold: 5},
				{value: "8-11 kg", threshold: 8},
				{value: "11-15 kg", threshold: 11},
				{value: "15+ kg", threshold: 15},
			]
		}
	]
;

pricingGrid_acadia_b2c.gridCells =
	[
		{
			coords: {wcat:"0-5 kg"},
			policy: {
				type: "FixedPrice",
				price: 13.9
			}
		},
		{
			coords: {wcat:"5-8 kg"},
			policy: {
				type: "FixedPrice",
				price: 15.9
			}
		},
		{
			coords: {wcat:"8-11 kg"},
			policy: {
				type: "FixedPrice",
				price: 18.9
			}
		},
		{
			coords: {wcat:"11-15 kg"},
			policy: {
				type: "FixedPrice",
				price: 20.9
			}
		},
		{
			coords: {wcat:"15+ kg"},
			policy: {
				type: "PerVolumePrice",
				dimension: "poids",
				rounding: 10,
				price: 7.4
			}
		}
	]
;



// TEST
let uneCommande = new CommandeALivrer("FCxxxxxx", 302 /*kg*/, "93420");

let xxx = pricingGrid_acadia_b2b.apply(uneCommande);



console.log(xxx);