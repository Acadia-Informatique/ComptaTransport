"use strict";

/** Customer-related computations.
 * Customers are defined by WS in API path /customers.
 */

var CustomerFunc = {

/**
 * Filter a list of AggShippingRevenue, to find the "monthly" product (= "Forfait mensuel (B2B)")
 * @param arr_aggShippingRevenue - (optional) *applicable* array of objs, with product among "MONTHLY" and QUOTE_MONTHLY" at least
 * @returns the "best" applicable one 
 */
getMonthlyOne : function(arr_aggShippingRevenue){
	let result = null;
	
	if (arr_aggShippingRevenue && arr_aggShippingRevenue.length > 0) {
		loopAggs:
		for (let aggRev of arr_aggShippingRevenue) {
			switch(aggRev.product){
			  case "QUOTE_MONTHLY" :
				if (!result) result = aggRev;
				break; 
			  case "MONTHLY" :
				result = aggRev;
				break loopAggs; // can't find better anyway
			}
		}
	}
	return result;
},


/**
 *
 * (*applicable* meaning : valid at the evaluation date)
 * @param isB2C - order is B2C or regular B2B. If true, can exclude some cases.
 * @param customer - obj with {id, tags}
 * @param shipPreferences - *applicable* single obj, with {tags, overrideCarrier}. BTW the latter is a String[] of names, not objs (hence the need of reflist_carriers)
 * @param arr_aggShippingRevenue - (optional) *applicable* array of objs, with product among "MONTHLY" and QUOTE_MONTHLY"
 * @param reflist_carriers - map of all <name, Carrier>. Carrier objs with {tags}.
 * @returns null if fees are to be paid ; if zero-fee, a String array of "reasons" (to be displayed, so localized - in French)
 */
assessZeroFee: function(isB2C, customer, shipPreferences, arr_aggShippingRevenue, reflist_carriers){
	let reasons = [];
	if (customer.tags.includes("Grand Compte")) {
		reasons.push(`Client "Grand Compte"`);
	}


	if (!isB2C && shipPreferences?.tags && shipPreferences.tags.includes("B2B: Franco")){
		reasons.push("Client déclaré \"Franco de port B2B\" sur la période.");
	}

	if (shipPreferences?.overrideCarriers?.length > 0){
		let areAllCarriersFree = shipPreferences.overrideCarriers
		.map(name => reflist_carriers.get(name))
		.every(c => c.tags.includes("Sans frais"));

		if (areAllCarriersFree){
			reasons.push(`Transports gratuits uniquement`);
		}
	}

	
	let monthlyAgg = CustomerFunc.getMonthlyOne(arr_aggShippingRevenue);
	if (!isB2C && monthlyAgg) {
		switch(monthlyAgg.product){
		  case "QUOTE_MONTHLY" :
			reasons.push(`Forfait à venir (B2B seulement)`); break;
		  case "MONTHLY" :
			reasons.push(`Forfait en cours (B2B seulement)`); break;
		}
	}

	return (reasons.length > 0) ? reasons : null;
}

};