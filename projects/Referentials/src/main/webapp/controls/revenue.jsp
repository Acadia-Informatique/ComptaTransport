<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

	<title>Contrôle Quotidien Transport</title>

	<%@ include file="/WEB-INF/includes/header-inc/client-stack.jspf" %>

	<%@ include file="/WEB-INF/includes/header-inc/vue-entityAttributeComponents.jspf"%>
	<%@ include file="/WEB-INF/includes/header-inc/vue-datepickers.jspf" %>

	<script src="${libsUrl}/pricegrid.js"></script>
	<script src="${libsUrl}/customer.js"></script>

	<style>
		/** Table styling */
		table#revenue-control-grid th div {
			height: 3em;
		}

		table#revenue-control-grid td.salesrep div {
			width: 6em;
		}
		table#revenue-control-grid th.cust.lbl div,
		table#revenue-control-grid td.cust.lbl div {
			width: 10em;
		}

		table#revenue-control-grid th,
		table#revenue-control-grid td {
			position: relative; /* for signal icons overlay */
		}

		table#revenue-control-grid td.erp-ref {
			position : sticky;
			left: 0;
			border: dotted 1px black;
			z-index: 500;
		}
		table#revenue-control-grid td > div.multiline {
			white-space:pre-wrap;
		}
		table#revenue-control-grid th.carrier,
		table#revenue-control-grid td.carrier {
			background-color: rgb(230, 255, 255);
		}

		table#revenue-control-grid th.price,
		table#revenue-control-grid td.price {
			background-color: rgb(255, 230, 230);
		}

		table#revenue-control-grid td.price.computed > div,
		table#revenue-control-grid td.carrier.computed > div {
			padding: 0.1em 0.3em;
			font-weight: bold;
		}
		table#revenue-control-grid td.price.computed > div {
			text-align: end;
		}

		table#revenue-control-grid td.price.comment > div,
		table#revenue-control-grid td.carrier.comment > div {
			width: 7em;
			font-weight: bold;
		}

		table#revenue-control-grid select,
		table#revenue-control-grid input,
		table#revenue-control-grid textarea {
			background-color: #ffffff80;
		}
		table#revenue-control-grid input {
			width: 3em;
		}
		table#revenue-control-grid textarea {
			min-width: 6em;
			field-sizing: content;
		}
		table#revenue-control-grid td.carrier.name > div[role="button"] {
			padding-left: 0.4em;<%-- closer text align with the edit version (html select) --%>
		}

		/* TODO NAM Q&D : assess Q&Dirtiness ;-) */
		table#revenue-control-grid tr.highlighted td {
			background-color: #ff9;
		}

	</style>
</head>

<body>
	<%@ include file="/WEB-INF/includes/body-inc/bs-confirmDialog.jspf" %>

	<div id="app" class="container-fluid">
		<h2>Contrôle quotidien des frais de transport facturés</h2>
		<div class="d-flex justify-content-between align-items-end">
			<div class="d-flex h-50 align-items-baseline mt-1">
				Date : <datepicker-day v-model="ctrlDate"></datepicker-day>
				<button class="btn btn-sm bi bi-funnel btn-secondary ms-2" @click="clearGridFilters"></button>

				<div v-if="dataRowCount" class="mx-2">{{ dataRowCount}} lignes</div>
			</div>

			<div v-if="pricingSystem['#pgv_metadata']" class="d-flex">
					Grille tarifaire ACADIA : {{ pricingSystem["#pgv_metadata"].version }}
					<audit-info class="small text-nowrap" v-model="pricingSystem['#pgv_metadata'].auditingInfo"></audit-info>
			</div>
		</div>
		<revenue-control-grid :date="ctrlDate" v-if="sharedReady" ref="gridRoot"
		  @row-count="dataRowCountChange"></revenue-control-grid>
	</div>

	<script type="text/javascript">
		// PricingSystem integration point
		class PricedObject {
			constructor(weight, country, zip, carrierObj, market, isHN, isInteg){
				this.weight = weight;
				this.country = country;
				this.zip = zip;
				this.carrierObj = carrierObj;
				this.market = market;
				this.isHN = isHN;
				this.isInteg = isInteg;

				// Internals are exposed to pricing system, namely a "PerVolumePrice" policy,
				// so we need this.poids as an equivalent to CommandeALivrer
				// currently used in grid-edit.jsp :
				this.poids = weight;

				Object.defineProperty(this, "poids_100_arr_10", {
				  get: ()=>{
					  return Math.ceil(this.poids / 10) / 10; //nb de centaines, après arrondi par 10 sup.
				  },
				  enumerable: true,
				});
			}
			getPPGRawCoordinates(){
				let departement = (this.country=="FR" && this.zip &&  this.zip.length==5) ? this.zip.substring(0,2) : "00";
				return {
					poids : this.weight,
					poidsEntier: Math.ceil(this.weight),
					poidsVolumique: this.weight, // TODO until we can do more... like :
					// poidsVolumique: Math.max(this.weight,
					//   (this.size_length * this.size_width * this.size_height) / 5000 // poids volumique d'après la fiche export
					// ),

					pays: this.country, //the whole chain uses ISO 3166-1 alpha-2
					departement,
					tailleHN : this.isHN ? "Oui" : "Non",
					nbColis : 1, // TODO maybe get this info, or remove it from grids
					transporteur100: this.carrierObj?.groupName,
					market: this.market,
					integration: this.isInteg ? "Oui" : "Non"
				};
			}
		}
	</script>

	<!-- =========================================================== -->
	<!-- =============== Vue components ============================ -->
	<script type="text/javascript">
		var LEVEL_NULL = 0, // means undefined, in most cases
		    LEVEL_BAD = 1,
		    LEVEL_WARN = 2;
		    LEVEL_OK = 3;
		var COUNT_LEVELS = 4; // used as modulo for cycling


		function _generic_OKclass(level, isBackground){
			switch(level){
				case LEVEL_OK   : return isBackground ? "text-bg-success" : "text-success";
				case LEVEL_WARN : return isBackground ? "text-bg-warning" : "text-warning";
				case LEVEL_BAD  : return isBackground ? "text-bg-danger"  : "text-danger";
				case LEVEL_NULL : default : return isBackground ? "text-bg-secondary" : "text-secondary";
			}
		}

		function _filterBtn_OKclass(level){
			const base = "position-absolute bottom-0 end-0 btn bi "
			switch(level){
				case LEVEL_OK   : return base + "text-success bi-funnel";
				case LEVEL_WARN : return base + "text-warning bi-funnel-fill";
				case LEVEL_BAD  : return base + "text-danger bi-funnel-fill";
				case LEVEL_NULL : default : return base + "text-primary bi-exclamation-triangle-fill"; // error, unexpected
			}
		}

		class Assessment {
			/* note : cellValue = expectedAmount when returned by assessAmount[...] */
			constructor(msg, level, cellValue){
				this.msg = msg;
				this.level = level;
				this.cellValue = cellValue;
			}
		}


		var RevenueControlGridRow = {
			inject: ["reflist_carriers", "pricingSystem", "otherPricingSystems",
			  "LEVEL_NULL", "LEVEL_BAD", "LEVEL_WARN", "LEVEL_OK", "COUNT_LEVELS"],
			props: ["rowData",
				"hideCarrierOKAbove", "hideFinalCarrOKAbove",
				"hideAmountOKAbove", "hideFinalAmntOKAbove"
			],
			data(){
				return {
					highlighted: false
				};
			},
			computed: {
				// shortened following a corporate habit
				rowData_invoice(){
					if (this.rowData.isGroup){
						return this.rowData.invoice_orig.split(";")
						  .map(s => AcadiaX3.shortInvoiceNumber(s))
						  .join("\n");
					} else {
						return AcadiaX3.shortInvoiceNumber(this.rowData.invoice);
					}
				},
				rowData_order(){
					return this.rowData.order.replaceAll(";","\n");
				},

				// mitigates 0.001 "dummy weight" in X3 (mandatory field there ;-)
				rowData_truncatedWeight(){return Math.floor(this.rowData.weight * 100) / 100;},

				rowData_customerShipPreferences(){
					if (this.rowData.customer?.shipPreferences && this.rowData.customer.shipPreferences.length > 0){
						return this.rowData.customer.shipPreferences[0];
					} else {
						return null;
					}
				},

				rowData_carrierObj() {
					return this.rowData.userInputs.carrier_override
					  ?? this.reflist_carriers.get(this.rowData.carrier);
				},

				rowDataCached_final_b2c(){ //to reduce priceGridResult reeval
					return typeof this.rowData.userInputs.b2c_override != 'undefined'
					  ? this.rowData.userInputs.b2c_override
					  : this.rowData["b2c"];
				},
				rowDataCached_nonstdPack(){ //to reduce priceGridResult reeval
					return this.rowData.userInputs.nonstdPack_override;
				},
				rowData_overridden_price(){
					//return this.rowData.price;  is much better, since it adds all products regardless of categorization
					// But in order to support partial override, we have to mimic the way our recommended
					// price is added up (cf. priceGridFlatResult_overridden_total and priceGridFlatResult.total())

					let sum = //for an unknown reason, i couldn't return it without assigning it to a temp var 1st.
						(this.rowData.userInputs.price_MAIN_override ?? ((this.rowData['P_MAIN']?.price) ?? 0))
					  + ((this.rowData['P_B2C']?.price) ?? 0)
					  + ((this.rowData['P_OPTS']?.price) ?? 0)
					  + ((this.rowData['P_UNK']?.price) ?? 0);
					return sum;
				},
				pricedObject(){
					return new PricedObject (
						this.rowData_truncatedWeight,
						this.rowData["country"],
						this.rowData["zip"],
						this.rowData_carrierObj,
						CustomerFunc.assessMarket(this.rowDataCached_final_b2c, this.rowData.customer, this.rowData_customerShipPreferences),
						this.rowDataCached_nonstdPack,
						this.rowData["carrier"] == "INTEGRATION" //instead of the overridden version : this.rowData_carrierObj.name == "INTEGRATION"
					);
				},
				priceGridResult(){
					console.debug("res", this.pricedObject);
					return this.pricingSystem.applyGrid("Toutes livraisons", this.pricedObject);
				},
				priceGridFlatResult(){
					console.debug("flatRes");
					return PricingSystem.summarizeResult(this.priceGridResult);
				},
				priceGridFlatResult_zone(){
					//TODO NAM Q&D
					let resultObj = this.priceGridResult;
					while (resultObj) {
						switch(resultObj.gridName){
							case "Toutes livraisons": {
								if (resultObj?.gridCell?.coords?.c == "Dom-Tom") return "DOM-TOM";
							} break;
							case "Prix Europe": {
								return "Europe " + resultObj?.gridCell?.coords?.c.replaceAll('Z', '');;
							} break;
							case "optim Transporteurs":{
								return resultObj?.gridCell?.coords?.z?.replaceAll('Zone 0', '');
							} break;
							default: break;
						}
						resultObj = resultObj.nested;
					}
				},
				priceGridFlatResult_carrier(){
					let reco = this.priceGridFlatResult?.extra_info;
					return reco ? reco + " ?" : "N/A";
				},

				assessCarrierOK(){
					console.debug("carrierOK");
					let selectedCarrier = this.rowData_carrierObj;
					if (selectedCarrier.warningMessage) {
						return new Assessment("Le transport choisi a été signalé comme problématique : \"" + selectedCarrier.warningMessage + "\"",
						  LEVEL_BAD, this.priceGridFlatResult_carrier);
					}

					if (!selectedCarrier.groupName) {
						return new Assessment("Sans \"groupe de contrôle\", le transport choisi \"" + selectedCarrier.name + "\" est toujours considéré comme OK.",
						  LEVEL_OK, "Non vérif.");
					}

					let recommended = (this.priceGridFlatResult.extra_info)
					  ? this.priceGridFlatResult.extra_info.split("/").map(s => s.trim())
					  : [];

					if (recommended.includes(selectedCarrier.groupName)){
						let overrides = [];
						if (this.rowData.userInputs.nonstdPack_override != null)
							overrides.push("HN");
						if (this.rowData.userInputs.b2c_override != null)
							overrides.push("B2C⚠️");
						if (this.rowData.userInputs.carrier_override != null)
							overrides.push("Transp. choisi⚠️");
						if (overrides.length > 0){
							return new Assessment("En tenant compte des modifications ("+ overrides +"), le transport choisi \"" + selectedCarrier.name + "\" devient conforme à la grille tarifaire Acadia",
							  LEVEL_OK, "OK (ajust.)");
						}

						return new Assessment("Le transport choisi \"" + selectedCarrier.name + "\" est recommandé dans la grille tarifaire Acadia",
						  LEVEL_OK, "OK");
					}

					if (this.rowData_customerShipPreferences){
						if (this.rowData_customerShipPreferences.overrideCarriers?.includes(selectedCarrier.name)){
							return new Assessment("Le transport choisi \"" + selectedCarrier.name + "\" est un transport exclusif de ce client.",
							  LEVEL_WARN, "OK Client");
						}

						if (selectedCarrier.tags.some(t => this.rowData_customerShipPreferences.carrierTagsWhitelist?.includes(t))) {
							return new Assessment("Le transport choisi \"" + selectedCarrier.name + "\" a été whitelisté par ce client.",
							  LEVEL_WARN, "Préf. Client");
						}

						let recommendedObj = [...this.reflist_carriers.values()].filter(c => recommended.includes(c.groupName));
						if (recommendedObj.length > 0 && recommendedObj.every(c => c.tags.some(t => this.rowData_customerShipPreferences?.carrierTagsBlacklist.includes(t)))){
							return new Assessment("Tous les transports recommandés ont été blacklistés par ce client : " + this.priceGridFlatResult_carrier,
							  LEVEL_WARN, "Refus Client");
						}
					}

					return new Assessment("Le transport choisi \"" + selectedCarrier.name + "\" n'a pas trouvé de justification automatique.",
					  LEVEL_BAD, this.priceGridFlatResult_carrier);
				},
				carrierOKclass(){
					return _generic_OKclass(this.assessCarrierOK.level, true);
				},

				assessFinalCarrOK_level(){
					return (this.rowData.userInputs.carrierOK_override > 0)
					  ? this.rowData.userInputs.carrierOK_override
					  : this.assessCarrierOK.level;
				},
				finalCarrOKclass(){
					return _generic_OKclass(this.assessFinalCarrOK_level, true);
				},

				assessAmountOK(){
					// do special cases 1st
					let selectedCarrier = this.rowData_carrierObj;
					if (selectedCarrier.tags.includes("Sans frais")) {
						return new Assessment("\"" + selectedCarrier.name + "\" est un transport sans frais",
						  LEVEL_OK, 0.0);
					}

					if (this.rowData.customer) {
						let zeroFee =  CustomerFunc.assessZeroFee(this.rowDataCached_final_b2c, this.rowData.customer, this.rowData_customerShipPreferences, this.rowData.customer.aggShippingRevenues, this.reflist_carriers);
						if (zeroFee) {
							return new Assessment("Client Franco de port - Raisons: " + zeroFee,
							  LEVEL_OK, 0.0);
						}
					}


					let alternatePriceGridResult;
					if (this.rowData_customerShipPreferences?.overridePriceGrid){
						let altSystem = this.otherPricingSystems.get(this.rowData_customerShipPreferences.overridePriceGrid.name);
						try {
							alternatePriceGridResult = altSystem.applyGrid("Toutes livraisons", this.pricedObject);
						} catch (err) {
							alert_dialog("Erreur Grille Tarifaire " + this.rowData_customerShipPreferences.overridePriceGrid.name,
							 "Une erreur s'est produite à l'application de la grille personnalisée du client "
							 + "\"" + this.rowData.customerLabel + "\" ["+ this.rowData.customerRef + "] : " + err.message);
						}
					}

					// customer B2C tag -> override PriceSystem computed value
					let cust_b2cAmount_override = null;
					if (this.rowDataCached_final_b2c && this.rowData_customerShipPreferences?.tags) {
						const B2C_tag_regex = /^B2C\s*:\s*(\d+[,\.]?\d*).*$/;
						for (let tag of this.rowData_customerShipPreferences.tags){
							let match = B2C_tag_regex.exec(tag);
							if (match) {
								cust_b2cAmount_override = Number.parseFloat(match[1].replace(",", "."));
								if (cust_b2cAmount_override) break;
							}
						}
					}

					// common case
					let baseFlatResult = PricingSystem.summarizeResult(alternatePriceGridResult ?? this.priceGridResult); // this rule may change, we could display ALL alternative results.
					// note: baseFlatResult may be equal to this.priceGridFlatResult at this stage,
					// but we may need to *alter* it - so better not share it.

					let baseMessage = "";
					if (alternatePriceGridResult) {
						baseMessage += ` Grille tarifaire personnalisée : "\${this.rowData_customerShipPreferences.overridePriceGrid.name}"`;
					}
					if (this.pricedObject.market == "B2C_as_B2B"){
						baseMessage += ` (+ option "B2C sur grille BTB")`;
					}
					if (cust_b2cAmount_override !== null){
						baseFlatResult["B2C"] = cust_b2cAmount_override;
						baseMessage += ` (+ option "supplém. B2C à \${cust_b2cAmount_override}")`;
					}

					let baseFlatResult_total = Math.round(100 * baseFlatResult.total()) / 100;
					let margin = Math.floor(100 * (this.rowData_overridden_price - baseFlatResult_total)) / 100;
					return new Assessment(baseMessage,
					  margin === 0 ? LEVEL_OK : (margin > 0 ? LEVEL_WARN : LEVEL_BAD),
					  isNaN(baseFlatResult_total) ? "N/A" : baseFlatResult_total);
				},

				amountOKclass(){
					return _generic_OKclass(this.assessAmountOK.level, true);
				},

				assessFinalAmntOK_level(){
					return (this.rowData.userInputs.amountOK_override > 0)
					  ? this.rowData.userInputs.amountOK_override
					  : this.assessAmountOK.level;
				},
				finalAmntOKclass(){
					return _generic_OKclass(this.assessFinalAmntOK_level, true);
				},
			},
			watch:{
				"rowData.userInputs":{
					handler(newV, oldV){
						if (newV._v_lock != oldV._v_lock) {
							// post-update reload, skip save
						} else {
							this.saveRowData();
						}
					},
					deep: 1

				}
			},
			methods: {
				saveRowData(){
					let rowDataClone = deepClone(this.rowData);

					// clean the "hard to track" useless overrides (like checkboxes)
					if (rowDataClone.userInputs.b2c_override == rowDataClone.b2c)
						delete rowDataClone.userInputs.b2c_override;

					axios_backend.put("transport-sales/" + this.rowData.id, rowDataClone)
					.then(response => {
						let updatedUserInputs = response.data.userInputs;
						if (updatedUserInputs?._v_lock != this.rowData.userInputs?._v_lock) {
							this.rowData.userInputs = updatedUserInputs;
						}
					})
					.catch(error => {
						showAxiosErrorDialog(error);
					});
				},
				debug_PricingSystem(){
					console.info("Interactive debug :",
						deepClone(this.rowData_carrierObj), // selected Carrier object
						deepClone(this.priceGridFlatResult), // PricingSystem flattened result, not necessarily used
						deepClone(this.priceGridResult) // PricingSystem complete result, not necessarily used
					);
				},
				cycleCarrierOKLevels(){
 					if (!this.rowData.userInputs.carrierOK_override) this.rowData.userInputs.carrierOK_override = 0;
					this.rowData.userInputs.carrierOK_override ++;
					this.rowData.userInputs.carrierOK_override %= COUNT_LEVELS;
				},
				cycleAmountOKLevels(){
 					if (!this.rowData.userInputs.amountOK_override) this.rowData.userInputs.amountOK_override = 0;
					this.rowData.userInputs.amountOK_override ++;
					this.rowData.userInputs.amountOK_override %= COUNT_LEVELS;
				},
				init_carrierOK_comment(ev){
					this.rowData.userInputs.carrierOK_comment = "???";
					const parentCell = ev.target.closest("td");
					this.$nextTick(()=>{
						let input = parentCell.getElementsByTagName("textarea")[0]
						input.focus();
						input.select();
					});
				},
				init_amountOK_comment(ev){
					this.rowData.userInputs.amountOK_comment = "???";
					const parentCell = ev.target.closest("td");
					this.$nextTick(()=>{
						let input = parentCell.getElementsByTagName("textarea")[0]
						input.focus();
						input.select();
					});
				},


				init_carrier_override(ev){
					this.rowData.$userInputs$carrier_override = this.reflist_carriers.get(this.rowData.carrier);
					const parentCell = ev.target.closest("td");
					this.$nextTick(()=>{
						parentCell.getElementsByTagName("select")[0].focus();
					});
				},
				validate_carrier_override(){
					let trueVal = this.rowData.carrier
					let newVal = this.rowData.$userInputs$carrier_override?.name ?? null;
					let oldVal = this.rowData.userInputs.carrier_override?.name ?? null;

					switch(newVal){
					case oldVal:
						console.debug("carrier_override unchanged");
						break;
					case trueVal :
						console.debug("carrier_override useless");
						if (oldVal !== null){
							console.debug("... and discarded");
							this.rowData.userInputs.carrier_override = null;
						} else {
							console.debug("... but was not set");
						}
						this.rowData.$userInputs$carrier_override = null;
						break;
					default:
						console.debug("price_MAIN_override changed");
						this.rowData.userInputs.carrier_override = this.rowData.$userInputs$carrier_override;
					}
				},

				init_price_MAIN_override(ev){
					this.rowData.$userInputs$price_MAIN_override = ((this.rowData['P_MAIN']?.price) ?? 0);
					const parentCell = ev.target.closest("td");
					this.$nextTick(()=>{
						let input = parentCell.getElementsByTagName("input")[0];
						input.focus();
						input.select();
					});
				},
				validate_price_MAIN_override(){
					/* to make them compatible with === and switch... */
					function _simpleValueOf(v){
						if (typeof v == "undefined" || v === null || v === ""){
							return null;
						} else if (Number.isFinite(v)){
							return Number.parseFloat(v);
						} else {
							return "NaN";
						}
					}
					let trueVal = _simpleValueOf(this.rowData['P_MAIN']?.price);
					let newVal = _simpleValueOf(this.rowData.$userInputs$price_MAIN_override);
					let oldVal = _simpleValueOf(this.rowData.userInputs.price_MAIN_override);

					switch(newVal){
					case "NaN":
						console.debug("price_MAIN_override rolled back");
						this.rowData.$userInputs$price_MAIN_override = oldVal;
						break;
					case oldVal:
						console.debug("price_MAIN_override unchanged");
						break;
					case trueVal :
						console.debug("price_MAIN_override useless");
						if (oldVal !== null){
							console.debug("... and discarded");
							this.rowData.userInputs.price_MAIN_override = null;
						} else {
							console.debug("... but was not set");
						}
						this.rowData.$userInputs$price_MAIN_override = null;
						break;
					default:
						console.debug("price_MAIN_override changed");
						this.rowData.userInputs.price_MAIN_override = newVal;
					}
				},

				activateCustomer(customerRef){
					customerRef = encodeURIComponent(customerRef);
					axios_backend.put(`customers/\${customerRef}/activate`)
					.then(response => {
						alert_dialog(`Client \"\${customerRef}\" réactivé`, "Pensez à rafraîchir la page !");
					})
					.catch(error => {
						showAxiosErrorDialog(error);
					});
				}
			},

			template: '#RevenueControlGridRow-template'
		};
	</script>

	<script type="text/x-template" id="RevenueControlGridRow-template">
		<tr v-show="assessCarrierOK.level <= hideCarrierOKAbove
		       && assessFinalCarrOK_level <= hideFinalCarrOKAbove
		       && assessAmountOK.level <= hideAmountOKAbove
		       && assessFinalAmntOK_level <= hideFinalAmntOKAbove"
		 @click="highlighted = !highlighted" :class="{'highlighted':highlighted}">
			<td class="erp-ref">
				<div :title="rowData.invoice" class="multiline" >{{ rowData_invoice }}</div>
			</td>
			<td>
				<div class="multiline">{{ rowData_order }}</div>
			</td>
			<td class="cust">
				<div v-if="rowData.customer">
					<template v-if="rowData.customer.tags.includes('inactive')">
						{{ rowData.customerRef }}
						<i role="button" class="bi bi-activity" title="Réactiver" @click="activateCustomer(rowData.customerRef)"></i>
					</template>
					<template v-else>
						<link-to-grid url="../customers" attr="erpReference" :value="rowData.customerRef"></link-to-grid>
 						<span v-if="rowData.customer.description" :title="rowData.customer.description">ℹ️</span>
					</template>
				</div>
				<div v-else>
					{{ rowData.customerRef }}
				</div>
			</td>
			<td class="cust lbl">
				<div :title="rowData.customerLabel" class="text-truncate"
				  @dblclick="$emit('filter-by-customer-label', rowData.customerLabel)">
					{{ rowData.customerLabel }}
				</div>
			</td>
			<td>
				<div>{{ rowData.country }}</div>
			</td>
			<td>
				<div>{{ rowData.zip }}</div>
			</td>
			<td>
				<div @click="debug_PricingSystem"> <%-- hidden debug feature --%>
					<datedisplay-day :value="rowData.date"></datedisplay-day>
				</div>
			</td>
			<td class="salesrep">
				<div :title="rowData.salesrep" class="text-truncate">{{ rowData.salesrep }}</div>
			</td>
			<td>
				<div :title="rowData_truncatedWeight" >{{ rowData.weight }}</div>
			</td>
			<td class="text-center">
				<div>
					<input v-model="rowData.userInputs.nonstdPack_override" type="checkbox" class="align-text-bottom"></input>
				</div>
			</td>
			<td class="text-center">
				<div v-if="typeof rowData.userInputs.b2c_override != 'undefined'">
					<override-signal />
					<input v-model="rowData.userInputs.b2c_override" type="checkbox" class="align-text-bottom"></input>
				</div>
				<div v-else role="button" @click="rowData.userInputs.b2c_override = !rowData.b2c">
					<i v-if="rowData.b2c" class="bi bi-check-square-fill"></i>
					<i v-else             class="bi bi-square"></i>
				</div>
			</td>
			<td class="carrier name" :title="rowData_carrierObj.groupName ? 'Contrôlé comme : '+ rowData_carrierObj.groupName : 'Transporteur non-vérifié'">
				<div v-if="rowData.$userInputs$carrier_override">
					<override-signal />
					<select v-model="rowData.$userInputs$carrier_override"
					  :title="'(initialement ' + rowData.carrier + ')'"
					  @change="validate_carrier_override"
					  @keyup.esc="$event.target.blur()">
						<option v-for="carrierObj in reflist_carriers.values()" :value="carrierObj">
							{{ carrierObj.name }}
						</option>
					</select>
				</div>
				<div v-else role="button" @click="init_carrier_override">
					{{ rowData.carrier }}
				</div>
			</td>
			<td class="carrier computed">
				<div :title="assessCarrierOK.msg" :class="carrierOKclass">
					{{ assessCarrierOK.cellValue }}
				</div>
			</td>
			<td class="carrier comment">
				<div :class="finalCarrOKclass">
					<textarea rows="1" v-if="rowData.userInputs.carrierOK_comment"
					      v-model.lazy.trim="rowData.userInputs.carrierOK_comment"
					  @keyup.esc="$event.target.blur()">>
					</textarea>
					<div v-else role="button" @click="init_carrierOK_comment">
						✏️
					</div>
					<div class="position-absolute bottom-0 end-0" role="button" @click="cycleCarrierOKLevels">
						🔃
					</div>
					<override-signal v-if="rowData.userInputs.carrierOK_override" />
				</div>
			</td>

<td><%-- TODO NAM Q&D --%>
	<div>{{ priceGridFlatResult_zone }}</div>
</td>
<td><%-- TODO NAM Q&D --%>
	<div :title="rowData_truncatedWeight" >{{ rowData.weight }}</div>
</td>


			<td class="price">
				<div v-if="Number.isFinite(rowData.$userInputs$price_MAIN_override)" >
					<override-signal />
					<input v-model.lazy.number="rowData.$userInputs$price_MAIN_override"
					  :title="'(initialement ' + rowData['P_MAIN']?.price + ')'"
					  @blur="validate_price_MAIN_override"
					  @keyup.esc="$event.target.blur()"></input>
				</div>
				<div v-else role="button" @click="init_price_MAIN_override"
				  :title="rowData['P_MAIN']?.desc">
					{{ rowData['P_MAIN']?.price }}
				</div>
			</td>
			<td class="price">
				<div :title="rowData['P_B2C']?.desc">{{ rowData['P_B2C']?.price}}</div>
			</td>
			<td class="price">
				<div :title="rowData['P_OPTS']?.desc">{{ rowData['P_OPTS']?.price}}
					<div v-if="rowData['P_UNK']?.price" class="alert alert-warning" role="alert">
							<i class="text-danger bi bi-exclamation-triangle-fill"></i> Produit non-conforme ici : {{ rowData['P_UNK']?.desc }}: {{ rowData['P_UNK']?.price }}
					</div>
				</div>
			</td>
			<td class="price computed">
				<div :title="'Prix originel dans X3 : ' + rowData.price">{{ rowData_overridden_price }}</div>
			</td>
			<td class="price computed">
				<div :title="assessAmountOK.msg" :class="amountOKclass">
					{{ assessAmountOK.cellValue }}
				</div>
			</td>
			<td class="price comment">
				<div :class="finalAmntOKclass">
					<textarea rows="1" v-if="rowData.userInputs.amountOK_comment"
					      v-model.lazy.trim="rowData.userInputs.amountOK_comment"
					  @keyup.esc="$event.target.blur()">
					</textarea>
					<div v-else role="button" @click="init_amountOK_comment">
						✏️
					</div>
					<div class="position-absolute bottom-0 end-0" role="button" @click="cycleAmountOKLevels">
						🔃
					</div>
					<override-signal v-if="rowData.userInputs.amountOK_override" />
				</div>
			</td>


		</tr>
	</script>

	<script type="text/javascript">
		var RevenueControlGrid = {
			props: {
				date:String
			},
			data() {
				return {
					dataList: [],
					hideCarrierOKAbove: LEVEL_OK,
					hideFinalCarrOKAbove: LEVEL_OK,
					hideAmountOKAbove: LEVEL_OK,
					hideFinalAmntOKAbove: LEVEL_OK,
					filterCustomerLabel: "",
					quick_and_dirty : null
				};
			},
			watch:{
				date:{
					immediate: true,
					handler(v){
						this.$emit("rowCount", null);
						if (!v) return; // fail silently for empty dates

						let resource_uri = "transport-sales?start-date="+ v;
						axios_backend.get(resource_uri)
						.then(response => {
							this.dataList = response.data;
							this.$emit("rowCount", this.dataList.length);

							for (let row of this.dataList){
								// prepare user inputs
								if (!row.userInputs){
									row.userInputs = {};
								} else {
									row.$userInputs$price_MAIN_override = row.userInputs.price_MAIN_override;
									row.$userInputs$carrier_override = row.userInputs.carrier_override;
								}

								// flattening of row.details
								for (let det of row.details){
									let entryKey = "P_" + det.type;
									if (row[entryKey]){
										row[entryKey] = {
											"price": row[entryKey].price + det.price,
											"desc": row[entryKey].desc + ";" + det.product
										};
									} else {
										row[entryKey] = {
											"price": det.price,
											"desc": det.product
										};
									}
								}
								delete row.details;
							}
						})
						.catch(error => {
							showAxiosErrorDialog(error);
						});
					}
				},

				//TODO NAM Q&D
				filterCustomerLabel(){
					if (this.filterCustomerLabel){
						this.quick_and_dirty = this.dataList;
						this.dataList = this.dataList.filter(row => row.customerLabel == this.filterCustomerLabel);
					} else {
						if (this.quick_and_dirty){
							this.dataList = this.quick_and_dirty;
						}
					}
				}
			},
			components:{
				"grid-row": RevenueControlGridRow,
			},
			computed:{
				hideCarrierOKAboveclass(){
					return _filterBtn_OKclass(this.hideCarrierOKAbove);
				},
				hideFinalCarrOKAboveclass(){
					return _filterBtn_OKclass(this.hideFinalCarrOKAbove);
				},
				hideAmountOKAboveclass(){
					return _filterBtn_OKclass(this.hideAmountOKAbove);
				},
				hideFinalAmntOKAboveclass(){
					return _filterBtn_OKclass(this.hideFinalAmntOKAbove);
				}
			},
			methods: {
				clearFilters(){
					this["hideCarrierOKAbove"] =
					this["hideFinalCarrOKAbove"] =
					this["hideAmountOKAbove"] =
					this["hideFinalAmntOKAbove"] = LEVEL_OK;

					this.filterCustomerLabel = null;
				},
				cycleFilter(name){
					let attributeName = "hide" + name +"Above";
					if (this[attributeName] == LEVEL_BAD) //LEVEL_NULL is excluded of filter values
						this[attributeName] = LEVEL_OK;
					else
						this[attributeName] --;
				},

				//TODO NAM Q&D
				filterByCustomerLabel(name){
					this.filterCustomerLabel = name;
				}
			},
			mounted(){
				const tooltipTriggerList = this.$refs.rootElement.querySelectorAll('[data-bs-toggle="tooltip"]');
				const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl))
			},
			template: '#RevenueControlGrid-template'
		};
	</script>

	<script type="text/x-template" id="RevenueControlGrid-template">
		<table id="revenue-control-grid" class="table table-bordered table-sm table-striped table-hover" ref="rootElement">
			<thead class="shadow sticky-top">
				<tr>
					<th data-bs-toggle="tooltip" title="Numéro de facture X3">
						<div>N° de facture</div>
					</th>
					<th data-bs-toggle="tooltip" title="Numéro Commande(s) correspondante(s) X3">
						<div>N° de commande</div>
					</th>
					<th class="cust" data-bs-toggle="tooltip" title="Numéro client X3">
						<div>N° Client</div>
					</th>
					<th class="cust lbl" data-bs-toggle="tooltip" title="Raison sociale du client X3">
						<div>Nom du client</div>
					</th>
					<th data-bs-toggle="tooltip" title="Pays de l'adresse d'expédition">
						<div>Pays</div>
					</th>
					<th data-bs-toggle="tooltip" title="Code postal de l'adresse d'expédition">
						<div>CP</div>
					</th>
					<th data-bs-toggle="tooltip" title="Date de facture X3">
						<div>Date de facture</div>
					</th>
					<th class="salesrep" data-bs-toggle="tooltip" title="Commercial ayant réalisé la vente">
						<div>Commercial</div>
					</th>
					<th data-bs-toggle="tooltip" title="Poids selon X3 (voir le poids arrondi pour les calculs dans la bulle d'aide)">
						<div>Poids</div>
					</th>
					<th data-bs-toggle="tooltip" title="Colisage Hors-Normes">
						<div>HN ? <override-signal /></div>
					</th>
					<th data-bs-toggle="tooltip" title="Livraison en Drop/BTC (actuellement déduit de la fiche Client ou de la présence d'un article &quot;Livraison directe&quot;)">
						<div>B2C ? <override-signal /></div>
					</th>

					<th class="carrier name" data-bs-toggle="tooltip" title="Transport choisi par le commercial">
						<div>Transp. choisi <override-signal /></div>
					</th>
					<th class="carrier computed" data-bs-toggle="tooltip" title="Transport recommandé (pour ce client ou par la grille standard)">
						<div>Transp. reco.</div>
						<i @click="cycleFilter('CarrierOK')" role="button" :class="hideCarrierOKAboveclass"></i>
					</th>
					<th class="carrier comment" data-bs-toggle="tooltip" title="Le transport choisi est-il conforme ?">
						<div>Transport OK ? <override-signal /></div>
						<i @click="cycleFilter('FinalCarrOK')" role="button" :class="hideFinalCarrOKAboveclass"></i>
					</th>
<th title="zone extraite aux forceps">Zone</th><%-- TODO NAM Q&D --%>
<th title="reprise du poids">Poids</th><%-- TODO NAM Q&D --%>
					<th class="price" data-bs-toggle="tooltip" title="Frais de port de base (voir Article X3 dans la bulle d'aide)">
						<div>Base <override-signal /></div>
					</th>
					<th class="price" data-bs-toggle="tooltip" title="Supplément &quot;Livraison directe&quot; (voir Article X3 dans la bulle d'aide)">
						<div>B2C</div>
					</th>
					<th class="price" data-bs-toggle="tooltip" title="Diverses options (voir Article X3 dans la bulle d'aide)">
						<div>Opt.</div>
					</th>
					<th class="price computed" data-bs-toggle="tooltip" title="Montant total des frais de port payés, selon X3">
						<div>Total</div>
					</th>
					<th class="price computed" data-bs-toggle="tooltip" title="Prix recommandé">
						<div>Prix reco</div>
						<i @click="cycleFilter('AmountOK')" role="button" :class="hideAmountOKAboveclass"></i>
					</th>
					<th class="price comment" data-bs-toggle="tooltip" title="Le prix recommandé est-il appliqué ?(voir la justification donnée dans la bulle d'aide)">
						<div>Prix OK ? <override-signal /></div>
						<i @click="cycleFilter('FinalAmntOK')" role="button" :class="hideFinalAmntOKAboveclass"></i>
					</th>
				</tr>
			</thead>
			<tbody>
				<TransitionGroup name="list">
				<grid-row v-for="rowData in dataList" :key="rowData.id" :rowData="rowData"
				  :hideCarrierOKAbove="hideCarrierOKAbove" :hideFinalCarrOKAbove="hideFinalCarrOKAbove"
				  :hideAmountOKAbove="hideAmountOKAbove"   :hideFinalAmntOKAbove="hideFinalAmntOKAbove"
				  @filter-by-customer-label="filterByCustomerLabel"
				></grid-row>
				</TransitionGroup>
			</tbody>
		</table>
	</script>

	<script type="module">
		function _updatePricingSystem(gridName, dt, system){
			let pgv_metadata_uri = "price-grids/*/versions/latest-of?grid-name="+ gridName +"&published-at=" + dt;
			axios_backend.get(pgv_metadata_uri)
			.then(response => {
				let pgv_metadata = response.data;

				if (!(pgv_metadata?.id)) {
					delete(system["#pgv_metadata"]);
					system.clear();

					throw new Error("Aucune grille publiée à la date demandée");
				}

				if (system["#pgv_metadata"]
				&& system["#pgv_metadata"]["id"] == pgv_metadata["id"]
					&& system["#pgv_metadata"]["_v_lock"] == pgv_metadata["_v_lock"]
				) {
					return; // pricingSystem already OK
				} else {
					delete(system["#pgv_metadata"]);
					system.clear();
				}


				let PRICE_GRID_ID = pgv_metadata.priceGrid.id;
				let PRICE_GRID_VERSION_ID = pgv_metadata.id;
				let dataUri =`price-grids/\${PRICE_GRID_ID}/versions/\${PRICE_GRID_VERSION_ID}/jsonContent`;

				axios_backend.get(dataUri)
				.then(response => {
					system.fromJSON(response.data);
					// note : pgv_metadata kept for display and browser cache invalidation
					system["#pgv_metadata"] = pgv_metadata;
				})
				.catch(error => {
					alert_dialog(`Récupération de la grille tarifaire \"\${gridName}\"`, error.message);
				});
			})
			.catch(error => {
				//showAxiosErrorDialog(error);
				alert_dialog(`Récupération de la grille tarifaire \"\${gridName}\" (entête)`, error.message);
			});
		};


		/* shared state for the page */
		const app = Vue.createApp({
			provide(){
				return {
					"reflist_carriers": this.reflist_carriers,
					"pricingSystem": Vue.reactive(this.pricingSystem),
					"otherPricingSystems": this.otherPricingSystems,
					LEVEL_NULL, LEVEL_BAD, LEVEL_WARN, LEVEL_OK, COUNT_LEVELS
				};
			},
			data(){
				return {
					ctrlDate: this.init_ctrlDate(),
					dataRowCount : null,

					pricingSystem: new PricingSystem(),
					otherPricingSystems: new Map(),
					reflist_carriers: new Map(),
				};
			},
			methods:{
				init_ctrlDate(){
					let storedDate = localStorage.getItem("controls/revenue/ctrlDate");
					return storedDate ?? Datepicker.currentDate();
				},
				loadRef_MainPricingSystem(dt){
					_updatePricingSystem("Acadia", dt, this.pricingSystem);
				},
				loadRef_OtherPricingSystem(dt){
					this.otherPricingSystems.forEach((system, pgname) => {
						_updatePricingSystem(pgname, dt, system)
					});
				},
				clearGridFilters(){
					this.$refs.gridRoot.clearFilters();
				},
				dataRowCountChange(rc){
					this.dataRowCount = rc;
				}
			},
			computed:{
				sharedReady(){ // almost a reactivity hack
					console.debug("shared ready");
					return !this.pricingSystem.isEmpty() > 0
					  && ![...this.otherPricingSystems.values()].some(system => system.isEmpty())
					  && this.reflist_carriers.size > 0;
				}
			},
			watch:{
				ctrlDate: {
					handler(v){
						localStorage.setItem("controls/revenue/ctrlDate", v);
						this.loadRef_MainPricingSystem(v);
						this.loadRef_OtherPricingSystem(v);
					},
					immediate: true
				}
			},
			created(){
				axios_backend.get("carriers")
				.then(response => {
					for (let carrier of response.data){
						this.reflist_carriers.set(carrier.name, carrier);
					}
				});

				axios_backend.get("price-grids?tag=Tarif+Spécial")
				.then(response => {
					for (let pricegrid of response.data){
						this.otherPricingSystems.set(pricegrid.name, new PricingSystem());
					}

					this.loadRef_OtherPricingSystem(this.ctrlDate);
				});
			}
		});

		app.component("override-signal", {
			template:"<span class=\"text-warning position-absolute top-0 end-0 me-1 opacity-75 pe-none\">⚠️</span>"
			//template:"<i class=\"text-warning bi bi-exclamation-octagon-fill position-absolute top-0 end-0 me-1 opacity-75 pe-none\"></i>"
		});

		app.component("datepicker-day", Datepicker_Day);
		app.component("audit-info", AuditingInfoRenderer);

		app.component("link-to-grid", LinkToGrid);
		app.component("datedisplay-day", Datedisplay_Day);
		app.component("revenue-control-grid", RevenueControlGrid);
		app.mount('#app');
	</script>
</body>



</html>
