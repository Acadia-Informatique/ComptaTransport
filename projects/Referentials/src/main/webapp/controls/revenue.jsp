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

	<style>
		/** Table readability */
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
			padding-left: 0.3em;
			font-weight: bold;
		}
		table#revenue-control-grid th,
		table#revenue-control-grid td {
			position: relative; /* for signal icons overlay */
		}


		table#revenue-control-grid select,
		table#revenue-control-grid input,
		table#revenue-control-grid textarea {
			background-color: #ffffff80;
		}
		table#revenue-control-grid textarea {
			min-width: 8em;
			field-sizing: content;
		}
		table#revenue-control-grid td.carrier > div[role="button"] {
			padding-left: 0.4em; /* closer text align with the select */
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
			</div>
			
			<div v-if="pricingSystem['#pgv_metadata']" class="d-flex">
					Grille tarifaire ACADIA : {{ pricingSystem["#pgv_metadata"].version }}
					<audit-info class="small text-nowrap" v-model="pricingSystem['#pgv_metadata'].auditingInfo"></audit-info>
			</div>
		</div>
		<revenue-control-grid :date="ctrlDate" v-if="sharedReady" ref="gridRoot"></revenue-control-grid>
	</div>

	<script type="text/javascript">
		class PricedObject {
			constructor(weight, country, zip, carrierObj, isB2C, isHN, isInteg){
				this.weight = weight;
				this.country = country;
				this.zip = zip;
				this.carrierObj = carrierObj;
				this.isB2C = isB2C;
				this.isHN = isHN;
				this.isInteg = isInteg;

				// Internals are exposed to pricing system, namely a "PerVolumePrice" policy,
				// so we need this.poids as an equivalent to CommandeALivrer
				// currently used in grid-edit.jsp :
				this.poids = weight;
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
					market: this.isB2C ? "BTC" : "BTB",
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
			switch(level){
				case LEVEL_OK   : return "text-success bi-funnel";
				case LEVEL_WARN : return "text-warning bi-funnel-fill";
				case LEVEL_BAD  : return "text-danger bi-funnel-fill";
				case LEVEL_NULL : default : return "text-primary bi-exclamation-triangle-fill"; // error, unexpected
			}			
		}
		


		var RevenueControlGridRow = {
			inject: ["reflist_carriers", "pricingSystem", "otherPricingSystems",
			  "LEVEL_NULL", "LEVEL_BAD", "LEVEL_WARN", "LEVEL_OK", "COUNT_LEVELS"],
			props: ["rowData", 
				"hideCarrierOKAbove", "hideFinalCarrOKAbove",
				"hideAmountOKAbove", "hideFinalAmntOKAbove"
			],
			computed: {
				// following a corporate habit
				rowData_shortInvoice(){ return AcadiaX3.shortInvoiceNumber(this.rowData.invoice)}
				,
				// mitigates 0.001 "dummy weight" in X3 (mandatory field there ;-)
				rowData_truncatedWeight(){return Math.floor(this.rowData.weight * 100) / 100;}
				,
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

				priceGridResult(){
					let pricedObject = new PricedObject (
						this.rowData_truncatedWeight,
						this.rowData["country"],
						this.rowData["zip"],
						this.rowData_carrierObj,
						this.rowDataCached_final_b2c,
						this.rowDataCached_nonstdPack,
						false//this.isInteg = isInteg;
					);
					console.debug("res", pricedObject);
					return this.pricingSystem.applyGrid("Toutes livraisons", pricedObject);
				},

				priceGridFlatResult(){
					console.debug("flatRes");
					return PricingSystem.summarizeResult(this.priceGridResult);
				},
				/** returns {msg:"...", level: one of the LEVEL_XXX}  */
				assessCarrierOK(){
					console.debug("carrierOK");
					let selectedCarrier = this.rowData_carrierObj;
					if (selectedCarrier.warningMessage) {
						return {msg: "Le transport choisi a été signalé comme problématique : \"" + selectedCarrier.warningMessage + "\"", level: LEVEL_BAD};
					}
					if (!selectedCarrier.groupName) {
						return {msg: "Sans \"groupe de contrôle\", le transport choisi \"" + selectedCarrier.name + "\" est toujours considéré comme OK.", level:LEVEL_OK};
					}

					let recommended;
					if (this.priceGridFlatResult.extra_info){
						recommended = this.priceGridFlatResult.extra_info.split("/").map(s => s.trim());
					}

					if (recommended?.includes(selectedCarrier.groupName)){
						return {msg: "Le transport choisi \"" + selectedCarrier.name + "\" est recommandé dans la grille tarifaire Acadia", level:LEVEL_OK};
					}

					let customerShipPreferences;
					if (this.rowData?.customer?.shipPreferences && this.rowData.customer.shipPreferences.length > 0){
						customerShipPreferences = this.rowData.customer.shipPreferences[0];
					}

					if (customerShipPreferences){
						if (customerShipPreferences.overrideCarriers?.includes(selectedCarrier.name)){
							return {msg: "Le transport choisi \"" + selectedCarrier.name + "\" est un transport exclusif de ce client.", level:LEVEL_WARN};
						}

						if (selectedCarrier.tags.some(t => customerShipPreferences.carrierTagsWhitelist?.includes(t))) {
							return {msg: "Le transport choisi a été whitelisté par ce client.", level:LEVEL_WARN};
						}

						let recommendedObj = [...this.reflist_carriers.values()].filter(c => recommended.includes(c.groupName));
						if (recommendedObj.every(c => c.tags.some(t => customerShipPreferences?.carrierTagsBlacklist.includes(t)))){
							return {msg: "Tous les transports recommandés ont été blacklistés par ce client.", level:LEVEL_WARN};
						}
					}

					return {msg: "Le transport choisi \"" + selectedCarrier.name + "\" n'a pas trouvé de justification automatique.", level:LEVEL_BAD};
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

				/** returns {msg:"...", expAmount: XXXX, level:i} where XXXX is the recommended amount, i in [0,2], 0 being "not OK" and 2 "perfectly OK" */
				assessAmountOK(){
					let selectedCarrier = this.rowData_carrierObj;
					if (selectedCarrier.tags.includes("Sans frais")) {
						return {msg:"Transport sans frais", expAmount: 0, level:LEVEL_OK};
					}

					let customerShipPreferences;
					if (this.rowData?.customer?.shipPreferences && this.rowData.customer.shipPreferences.length > 0){
						customerShipPreferences = this.rowData.customer.shipPreferences[0];
					}
					let aggShippingRevenue;
					if (this.rowData?.customer?.aggShippingRevenues && this.rowData.customer.aggShippingRevenues.length > 0){
						aggShippingRevenue = this.rowData.customer.aggShippingRevenues[0];
					}


					if (customerShipPreferences) {
						if (customerShipPreferences.overridePriceGrid){
							//TODO cache & appliquer .overridePriceGrid

							//get_MainPricingSystem(dt){
							//	_updatePricingSystem(customerShipPreferences.overridePriceGrid, dt, this.pricingSystem);
							//},

							console.warn(customerShipPreferences.overridePriceGrid);
							console.warn(this.otherPricingSystems.get("sim"));
							return {msg: "Le client possède une grille tarifaire personnalisée : \"TODO", expAmount: 777, level:LEVEL_BAD};
						}
					}

					if (aggShippingRevenue && aggShippingRevenue.product == "MONTHLY"){
						return {msg: "Le client possède ce mois-ci un \"forfait transport B2B\" à " +aggShippingRevenue.amount+ "€", expAmount: this.priceGridFlatResult.total(), level:LEVEL_WARN};
					}

					let cust_b2cAmount_override;
					if (customerShipPreferences) {
						const B2C_tag_regex = /^B2C\s*:\s*(\d+[,\.]?\d*).*$/;
						for (let tag of customerShipPreferences.tags){
							let match = B2C_tag_regex.exec(tag);
							if (match) {
								cust_b2cAmount_override = Number.parseFloat(match[1].replace(",", "."));
								if (cust_b2cAmount_override) break;
							}
						}
					}
					if (cust_b2cAmount_override){
						this.priceGridFlatResult["B2C"] = cust_b2cAmount_override;
					}


					let margin = this.rowData.price - this.priceGridFlatResult.total();
					let result = {msg: (margin>=0 ?"Nul ou Positif":"Négatif"), expAmount: this.priceGridFlatResult.total(), level: (margin>=0 ? LEVEL_OK : LEVEL_BAD)};
					if (cust_b2cAmount_override){
						result.msg = result.msg + ` (avec supplém. B2C spécial du client à \${cust_b2cAmount_override})`;
					}
					return result;
				},

				amountOKclass(){
					return _generic_OKclass(this.assessAmountOK.level, true);
				},
				
				assessFinalAmntOK_level(){
					return (this.rowData.userInputs.amountOK_override > 0)
					  ? this.rowData.userInputs.amountOK_override
					  : this.assessAmountOK.level;					
				},
				finalAmountOKclass(){
					return _generic_OKclass(this.assessFinalAmntOK_level, true);
				},
			},
			watch:{
				"rowData.userInputs":{
					handler(newV, oldV){
						if (newV._v_lock != oldV._v_lock // post-update reload
						  || (newV.carrier_override != null && oldV.carrier_override == null) // init override with same value
						) {
							// not a real change, skip save
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

					if (rowDataClone.userInputs.b2c_override == rowDataClone.b2c)
						delete rowDataClone.userInputs.b2c_override;
					if (rowDataClone.userInputs.carrier_override?.name == rowDataClone.carrier)
						delete rowDataClone.userInputs.carrier_override;


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

				enableCustomer(customerRef){
					// TODO écrire le service, + refresh la ligne (toutes les lignes ?...)
					console.info(" reactiver " + customerRef);
				}
			},

			template: '#RevenueControlGridRow-template'
		};
	</script>

	<script type="text/x-template" id="RevenueControlGridRow-template">
		<tr v-if="assessCarrierOK.level <= hideCarrierOKAbove
		       && assessFinalCarrOK_level <= hideFinalCarrOKAbove
		       && assessAmountOK.level <= hideAmountOKAbove
		       && assessFinalAmntOK_level <= hideFinalAmntOKAbove" >
			<td class="position-sticky">
				<div>{{ rowData_shortInvoice }}</div>
			</td>
			<td>
				<div>{{ rowData.order }}</div>
			</td>
			<td>
				<div v-if="rowData.customer">
					<div v-if="rowData.customer.tags.includes('inactive')">
						{{ rowData.customerRef }}
						<button class="btn btn-sm btn-secondary bi bi-activity" title="Réactiver" @click="enableCustomer(rowData.customerRef)"></button>
					</div>
					<link-to-grid v-else url="../customers" attr="erpReference" :value="rowData.customerRef"></link-to-grid>
				</div>
				<div v-else>
					{{ rowData.customerRef }}
					<button class="btn btn-sm btn-primary" @click="enableCustomer(rowData.customerRef)">Créer</button>
				</div>
			</td>
			<td>
				<div :title="JSON.stringify(rowData.customer)">
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
			<td>
				<div>{{ rowData.salesrep }}</div>
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
			<td class="carrier" :title="rowData_carrierObj.groupName ? 'Contrôlé comme : '+ rowData_carrierObj.groupName : 'Transporteur non-vérifié'">
				<div v-if="rowData.userInputs.carrier_override">
					<override-signal />
					<select v-model="rowData.userInputs.carrier_override" :title="'(initialement ' + rowData.carrier + ')'">
						<option v-for="carrierObj in reflist_carriers.values()" :value="carrierObj">
							{{ carrierObj.name }}
						</option>
					</select>
				</div>
				<div v-else role="button" @click="rowData.userInputs.carrier_override = reflist_carriers.get(rowData.carrier)">
					{{ rowData.carrier }}
				</div>
			</td>
			<td class="carrier computed">
				<div :title="assessCarrierOK.msg" :class="carrierOKclass">
 					<template v-if="assessCarrierOK.level > LEVEL_BAD">OK</template>
					<template v-else>{{ priceGridFlatResult?.extra_info }} ?</template>
				</div>
			</td>
			<td class="carrier computed">
				<div :class="finalCarrOKclass">
					<textarea rows="1" v-if="rowData.userInputs.carrierOK_comment"
					      v-model.lazy.trim="rowData.userInputs.carrierOK_comment">
					</textarea>
					<div v-else role="button" @click="rowData.userInputs.carrierOK_comment = ' '">
						✏️
					</div>
					<div class="position-absolute bottom-0 end-0" role="button" @click="cycleCarrierOKLevels">
						🔃
					</div>
					<override-signal v-if="rowData.userInputs.carrierOK_override" />
				</div>
			</td>

			<td class="price">
				<div :title="rowData['P_MAIN']?.desc">{{ rowData['P_MAIN']?.price}}</div>
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

			<td class="price">
				<div>{{ rowData.price }}</div>
			</td>
			<td class="price computed">
				<div :title="assessAmountOK.msg" :class="amountOKclass">
 					<template v-if="assessAmountOK.level">
						{{ assessAmountOK.expAmount - rowData.price ?? "OK" }}
					</template>
					<template v-else>
						{{ assessAmountOK.expAmount }} ?
					</template>
				</div>
			</td>
			<td class="price computed">
				<div :class="amountOKclass">
					TODO copy carrier
					<textarea v-model="rowData.userInputs.amountOK_comment"></textarea>
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
				};
			},
			watch:{
				date:{
					immediate: true,
					handler(v){
						if (!v) return; // fail silently for empty dates

						let resource_uri = "transport-sales?start-date="+ v;
						axios_backend.get(resource_uri)
						.then(response => {
							this.dataList = response.data;

							for (let row of this.dataList){
								// prepare user inputs
								if (!row.userInputs){
									row.userInputs = {};
								}

								// flattening of row.details
								for (let det of row.details){
									let entryKey = "P_" + det.type;
									if (row[entryKey]){
										row[entryKey] = {
											"price": row[entryKey].price + det.price,
											"desc": row[entryKey].product + ";" + det.product
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
				}
			},
			methods: {
				clearFilters(){
					this["hideCarrierOKAbove"] = 
					this["hideFinalCarrOKAbove"] = 
					this["hideAmountOKAbove"] = 
					this["hideFinalAmntOKAbove"] = LEVEL_OK;
					
				},
				cycleFilter(name){
					let attributeName = "hide" + name +"Above";
					if (this[attributeName] == LEVEL_BAD) //LEVEL_NULL is excluded of filter values
						this[attributeName] = LEVEL_OK;
					else
						this[attributeName] --;
				},
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
					<th data-bs-toggle="tooltip" title="Numéro de facture X3" class="position-sticky">
						<div>N° de facture</div>
					</th>
					<th data-bs-toggle="tooltip" title="Numéro Commande(s) correspondante(s) X3">
						<div>N° de commande</div>
					</th>
					<th data-bs-toggle="tooltip" title="Numéro client X3">
						<div>N° du client</div>
					</th>
					<th data-bs-toggle="tooltip" title="Raison sociale du client X3">
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
					<th data-bs-toggle="tooltip" title="Commercial ayant réalisé la vente">
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

					<th class="carrier" data-bs-toggle="tooltip" title="Transport choisi par le commercial">
						<div>Transp. choisi <override-signal /></div>
					</th>
					<th class="carrier computed" data-bs-toggle="tooltip" title="Transport recommandé (pour ce client ou par la grille standard)">
						<div>Transp. reco.</div>
						<i @click="cycleFilter('CarrierOK')" role="button" class="position-absolute bottom-0 end-0 btn bi" :class="hideCarrierOKAboveclass"></i>
					</th>
					<th class="carrier computed" data-bs-toggle="tooltip" title="Le transport choisi est-il conforme ?">
						<div>Transport OK ? <override-signal /></div>
						<i @click="cycleFilter('FinalCarrOK')" role="button" class="position-absolute bottom-0 end-0 btn bi" :class="hideFinalCarrOKAboveclass"></i>
					</th>

					<th class="price" data-bs-toggle="tooltip" title="Frais de port de base (voir Article X3 dans la bulle d'aide)">
						<div>Base</div>
					</th>
					<th class="price" data-bs-toggle="tooltip" title="Supplément &quot;Livraison directe&quot; (voir Article X3 dans la bulle d'aide)">
						<div>B2C</div>
					</th>
					<th class="price" data-bs-toggle="tooltip" title="Diverses options (voir Article X3 dans la bulle d'aide)">
						<div>Opt.</div>
					</th>

					<th class="price" data-bs-toggle="tooltip" title="Montant total des frais de port payés, selon X3">
						<div>Total</div>
					</th>
					<th class="price computed" data-bs-toggle="tooltip" title="Prix recommandé">
						<div>Prix reco</div>
					</th>
					<th class="price computed" data-bs-toggle="tooltip" title="Le prix recommandé est-il appliqué ?(voir la justification donnée dans la bulle d'aide)">
						<div>Prix OK ?</div>
					</th>
				</tr>
			</thead>
			<tbody>
				<TransitionGroup name="list">
				<grid-row v-for="rowData in dataList" :key="rowData.id" :rowData="rowData"
				  :hideCarrierOKAbove="hideCarrierOKAbove" :hideFinalCarrOKAbove="hideFinalCarrOKAbove"
				  :hideAmountOKAbove="hideAmountOKAbove"   :hideFinalAmntOKAbove="hideFinalAmntOKAbove"
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
					"otherPricingSystems": {
						_map : new Map(),
						get(gridName){
							return this._map.get(gridName);
						}
					},
					LEVEL_NULL, LEVEL_BAD, LEVEL_WARN, LEVEL_OK, COUNT_LEVELS
				};
			},
			data(){
				return {
					ctrlDate: Datepicker.currentDate(),
					pricingSystem: new PricingSystem(),
					reflist_carriers: new Map(),
				};
			},
			methods:{
				loadRef_MainPricingSystem(dt){
					_updatePricingSystem("Acadia", dt, this.pricingSystem);
				},
				loadRef_Carriers(){
					this.reflist_carriers.clear();
					axios_backend.get("carriers")
					.then(response => {
						for (let carrier of response.data){
							this.reflist_carriers.set(carrier.name, carrier);
						}
					});
				},
				clearGridFilters(){
					this.$refs.gridRoot.clearFilters();
				}
			},
			computed:{
				sharedReady(){ // almost a reactivity hack
					console.debug("shared ready");
					return !this.pricingSystem.isEmpty() > 0
					  && this.reflist_carriers.size > 0;
				}
			},
			watch:{
				ctrlDate: {
					handler(v){
						this.loadRef_MainPricingSystem(v);
					},
					immediate: true
				}
			},
			created(){
				this.loadRef_Carriers();
			}
		});

		app.component("override-signal", {
			template:"<i class=\"text-warning bi bi-exclamation-octagon-fill position-absolute top-0 end-0 me-1 opacity-75 pe-none\"></i>"
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
