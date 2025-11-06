"use strict";

/** Default grids a,d policies used in the "Referentials" database application.
 * They are not needed for the JS PricingGrid engine.
 */

var DEFAULT_POLICIES = {
	"FixedPrice": {
		type: "FixedPrice",
		price: null
	},
	"PerVolumePrice": {
		type: "PerVolumePrice",
		attribute: null,
		rounding: 10,
		price: null,
		/* offset : {
			attribute:0,
			price:0
		} */
	},
	"DelegatedPrice": {
		type: "DelegatedPrice",
		delegated_gridName: "",
		delegated_additiveAmount: null
	},
};

var EMPTY_PRICINGSYSTEM = new PricingSystem();
EMPTY_PRICINGSYSTEM.grids.push(new PricingGrid("Grille_1"));

let sampleData = {
	"grids": [
		{
			"name": "B2B",
			"dimensions": [
				{
					"type": "ThresholdCategory",
					"name": "p",
					"raw_name": "poids",
					"categories": [
						{
							"value": 0
						},
						{
							"value": 5
						},
						{
							"value": 10
						},
						{
							"value": 20
						},
						{
							"value": 50
						}
					],
					"comparison": "strictSup"
				},
				{
					"type": "EnumCategory",
					"name": "z",
					"raw_name": "departement",
					"categories": [
						{
							"value": "Zone A",
							"enum": [
								"75",
								"77",
								"78",
								"91",
								"92",
								"93",
								"94",
								"95",
								"02",
								"08",
								"10",
								"14",
								"18",
								"27",
								"28",
								"36",
								"37",
								"41",
								"45",
								"51",
								"58",
								"59",
								"60",
								"61",
								"62",
								"72",
								"76",
								"80",
								"89",
								"01",
								"03",
								"07",
								"15",
								"21",
								"23",
								"24",
								"26",
								"29",
								"35",
								"39",
								"42",
								"43",
								"44",
								"47",
								"48",
								"49",
								"50",
								"52",
								"53",
								"54",
								"55",
								"63",
								"69",
								"70",
								"71",
								"86",
								"87",
								"88"
							]
						},
						{
							"value": "Zone B",
							"enum": [
								"16",
								"17",
								"19",
								"22",
								"25",
								"33",
								"38",
								"56",
								"57",
								"67",
								"68",
								"73",
								"74",
								"79",
								"85",
								"90",
								"04",
								"05",
								"65",
								"83",
								"98",
								"06",
								"09",
								"11",
								"12",
								"13",
								"30",
								"31",
								"32",
								"34",
								"40",
								"46",
								"64",
								"66",
								"81",
								"82",
								"84"
							]
						},
						{
							"value": "Corse",
							"enum": [
								"20"
							]
						}
					]
				}
			],
			"gridCells": [
				{
					"coords": {
						"z": "Zone A",
						"p": 0
					},
					"policy": {
						"type": "FixedPrice",
						"price": 5
					}
				},
				{
					"coords": {
						"z": "Zone A",
						"p": 5
					},
					"policy": {
						"type": "FixedPrice",
						"price": 7
					}
				},
				{
					"coords": {
						"z": "Zone A",
						"p": 10
					},
					"policy": {
						"type": "FixedPrice",
						"price": 11
					}
				},
				{
					"coords": {
						"z": "Zone A",
						"p": 20
					},
					"policy": {
						"type": "FixedPrice",
						"price": 35
					}
				},
				{
					"coords": {
						"z": "Zone A",
						"p": 50
					},
					"policy": {
						"type": "PerVolumePrice",
						"attribute": "poids",
						"rounding": 10,
						"price": 2.13,
						"offset": {
							"attribute": 50,
							"price": 35
						}
					}
				},
				{
					"coords": {
						"z": "Zone B",
						"p": 0
					},
					"policy": {
						"type": "FixedPrice",
						"price": 8
					}
				},
				{
					"coords": {
						"z": "Zone B",
						"p": 5
					},
					"policy": {
						"type": "FixedPrice",
						"price": 12
					}
				},
				{
					"coords": {
						"z": "Zone B",
						"p": 10
					},
					"policy": {
						"type": "FixedPrice",
						"price": 30
					}
				},
				{
					"coords": {
						"z": "Zone B",
						"p": 20
					},
					"policy": {
						"type": "FixedPrice",
						"price": 40
					}
				},
				{
					"coords": {
						"z": "Zone B",
						"p": 50
					},
					"policy": {
						"type": "PerVolumePrice",
						"attribute": "poids",
						"rounding": 10,
						"price": 3.02,
						"offset": {
							"attribute": 50,
							"price": 40
						}
					}
				},
				{
					"coords": {
						"z": "Corse",
						"p": 0
					},
					"policy": {
						"type": "FixedPrice",
						"price": 35
					}
				},
				{
					"coords": {
						"z": "Corse",
						"p": 5
					},
					"policy": {
						"type": "FixedPrice",
						"price": 48
					}
				},
				{
					"coords": {
						"z": "Corse",
						"p": 10
					},
					"policy": {
						"type": "FixedPrice",
						"price": 80
					}
				},
				{
					"coords": {
						"z": "Corse",
						"p": 20
					},
					"policy": null
				},
				{
					"coords": {
						"z": "Corse",
						"p": 50
					},
					"policy": null
				}
			]
		},
		{
			"name": "B2C",
			"dimensions": [
				{
					"type": "EnumCategory",
					"name": "z",
					"raw_name": "departement",
					"categories": [
						{
							"value": "Corse",
							"enum": [
								"20"
							]
						},
						{
							"value": "autres",
							"enum": [
								"75",
								"77",
								"78",
								"91",
								"92",
								"93",
								"94",
								"95",
								"02",
								"08",
								"10",
								"14",
								"18",
								"27",
								"28",
								"36",
								"37",
								"41",
								"45",
								"51",
								"58",
								"59",
								"60",
								"61",
								"62",
								"72",
								"76",
								"80",
								"89",
								"01",
								"03",
								"07",
								"15",
								"21",
								"23",
								"24",
								"26",
								"29",
								"35",
								"39",
								"42",
								"43",
								"44",
								"47",
								"48",
								"49",
								"50",
								"52",
								"53",
								"54",
								"55",
								"63",
								"69",
								"70",
								"71",
								"86",
								"87",
								"88",
								"16",
								"17",
								"19",
								"22",
								"25",
								"33",
								"38",
								"56",
								"57",
								"67",
								"68",
								"73",
								"74",
								"79",
								"85",
								"90",
								"04",
								"05",
								"65",
								"83",
								"98",
								"06",
								"09",
								"11",
								"12",
								"13",
								"30",
								"31",
								"32",
								"34",
								"40",
								"46",
								"64",
								"66",
								"81",
								"82",
								"84"
							]
						}
					]
				}
			],
			"gridCells": [
				{
					"coords": {
						"z": "Corse"
					},
					"policy": {
						"type": "DelegatedPrice",
						"delegated_gridName": "B2B",
						"delegated_additiveAmount": 35
					}
				},
				{
					"coords": {
						"z": "autres"
					},
					"policy": {
						"type": "DelegatedPrice",
						"delegated_gridName": "B2B",
						"delegated_additiveAmount": 3
					}
				}
			]
		}
	]
};
var SAMPLE_PRICINGSYSTEM = PricingSystem.fromJSON(sampleData);