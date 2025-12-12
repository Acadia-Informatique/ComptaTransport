<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

	<title>Contrôle Mensuel Transport</title>

	<%@ include file="/WEB-INF/includes/header-inc/client-stack.jspf" %>

	<%@ include file="/WEB-INF/includes/header-inc/vue-entityAttributeComponents.jspf"%>
	<%@ include file="/WEB-INF/includes/header-inc/vue-datepickers.jspf" %>

	<script src="${libsUrl}/pricegrid.js"></script>
	<script src="${libsUrl}/customer.js"></script>

	<style>
		/** Table styling
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
 */
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
		<h2>Contrôle mensuel des factures Transporteur</h2>
		<div class="d-flex justify-content-between align-items-end">
			<div class="d-flex h-50 align-items-baseline mt-1">
				Période : <datepicker-month v-model="ctrlDate"></datepicker-month>
				<button class="btn btn-sm bi bi-funnel btn-secondary ms-2" @click="clearGridFilters"></button>

				<div v-if="dataRowCount" class="mx-2">{{ dataRowCount}} lignes</div>
			</div>
<%--
			<div v-if="pricingSystem['#pgv_metadata']" class="d-flex">
					Grille tarifaire ACADIA : {{ pricingSystem["#pgv_metadata"].version }}
					<audit-info class="small text-nowrap" v-model="pricingSystem['#pgv_metadata'].auditingInfo"></audit-info>
			</div>
--%>
		</div>
		<revenue-control-grid :date="ctrlDate" v-if="sharedReady" ref="gridRoot"
		  @row-count="dataRowCountChange"></revenue-control-grid>
	</div>

	<script type="text/javascript">
		// PricingSystem integration point
		class PricedObject {
			constructor(weight, country, zip){
				this.weight = weight;
				this.country = country;
				this.zip = zip;


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
					// poidsVolumique: Math.max(this.weight,
					//   (this.size_length * this.size_width * this.size_height) / 5000 // poids volumique d'après la fiche export
					// ),

					pays: this.country, //the whole chain uses ISO 3166-1 alpha-2
					departement,
					nbColis : 1, // TODO maybe get this info, or remove it from grids
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
			inject: ["priceGrids",
			  "LEVEL_NULL", "LEVEL_BAD", "LEVEL_WARN", "LEVEL_OK", "COUNT_LEVELS"],
			props: ["rowData",
					"hideWeightOKAbove",
					"hideTheirAmountOKAbove",
					"hideOurMarginOKAbove"
			],
			data(){
				return {
					highlighted: false
				};
			},
			computed: {
				priceGridResult(){
					let pgpath_items = this.rowData.article.pricegridPath.split("/");
					let dbGridName = pgpath_items[0]; // database entity PriceGrid name (home of a list of PriceGridVersion, each containing a JS PricingSystem...)
					let jsGridName = pgpath_items[1]; // entry key for a PricingGrid JS instance inside a PricingSystem JS object (a tab in the grid-edit.jsp).
					
					let dbGrid = this.priceGrids.find(pg => pg.name == dbGridName);
					let applicableVersion = dbGrid["#versions"].find(v => v.publishedDate <= this.rowData.carrierOrderDate);
					
					if (!applicableVersion) return null;
					
					let system = applicableVersion["#system"];
										
					let pricedObject = new PricedObject(
						this.rowData.totalWeight,
						this.rowData.shipCountry,
						this.rowData.shipZipcode
					);
	
					return system.applyGrid(jsGridName, pricedObject);
				},
				// shortened following a corporate habit

				// rowData_invoice(){
				// 	if (this.rowData.isGroup){
				// 		return this.rowData.invoice_orig.split(";")
				// 		  .map(s => AcadiaX3.shortInvoiceNumber(s))
				// 		  .join("\n");
				// 	} else {
				// 		return AcadiaX3.shortInvoiceNumber(this.rowData.invoice);
				// 	}
				// },
				// rowData_order(){
				// 	return this.rowData.order.replaceAll(";","\n");
				// },

				// // mitigates 0.001 "dummy weight" in X3 (mandatory field there ;-)
				// rowData_truncatedWeight(){return Math.floor(this.rowData.weight * 100) / 100;},

				// rowData_customerShipPreferences(){
				// 	if (this.rowData.customer?.shipPreferences && this.rowData.customer.shipPreferences.length > 0){
				// 		return this.rowData.customer.shipPreferences[0];
				// 	} else {
				// 		return null;
				// 	}
				// },

				// rowDataCached_final_b2c(){ //to reduce priceGridResult reeval
				// 	return typeof this.rowData.userInputs.b2c_override != 'undefined'
				// 	  ? this.rowData.userInputs.b2c_override
				// 	  : this.rowData["b2c"];
				// },
				// rowDataCached_nonstdPack(){ //to reduce priceGridResult reeval
				// 	return this.rowData.userInputs.nonstdPack_override;
				// },
				// rowData_overridden_price(){
				// 	//return this.rowData.price;  is much better, since it adds all products regardless of categorization
				// 	// But in order to support partial override, we have to mimic the way our recommended
				// 	// price is added up (cf. priceGridFlatResult_overridden_total and priceGridFlatResult.total())

				// 	let sum = //for an unknown reason, i couldn't return it without assigning it to a temp var 1st.
				// 		(this.rowData.userInputs.price_MAIN_override ?? ((this.rowData['P_MAIN']?.price) ?? 0))
				// 	  + ((this.rowData['P_B2C']?.price) ?? 0)
				// 	  + ((this.rowData['P_OPTS']?.price) ?? 0)
				// 	  + ((this.rowData['P_UNK']?.price) ?? 0);
				// 	return sum;
				// },
				// pricedObject(){
				// 	return new PricedObject (
				// 		this.rowData_truncatedWeight,
				// 		this.rowData["country"],
				// 		this.rowData["zip"],
				// 		this.rowData_carrierObj,
				// 		CustomerFunc.assessMarket(this.rowDataCached_final_b2c, this.rowData.customer, this.rowData_customerShipPreferences),
				// 		this.rowDataCached_nonstdPack,
				// 		this.rowData_carrierObj.name == "INTEGRATION"
				// 	);
				// },
				// priceGridResult(){
				// 	console.debug("res", this.pricedObject);
				// 	return this.pricingSystem.applyGrid("Toutes livraisons", this.pricedObject);
				// },
				// priceGridFlatResult(){
				// 	console.debug("flatRes");
				// 	return PricingSystem.summarizeResult(this.priceGridResult);
				// },
				// priceGridFlatResult_zone(){
				// 	//TODO NAM Q&D
				// 	let resultObj = this.priceGridResult;
				// 	while (resultObj) {
				// 		switch(resultObj.gridName){
				// 			case "Toutes livraisons": {
				// 				if (resultObj?.gridCell?.coords?.c == "Dom-Tom") return "DOM-TOM";
				// 			} break;
				// 			case "Prix Europe": {
				// 				return "Europe " + resultObj?.gridCell?.coords?.c.replaceAll('Z', '');;
				// 			} break;
				// 			case "optim Transporteurs":{
				// 				return resultObj?.gridCell?.coords?.z?.replaceAll('Zone 0', '');
				// 			} break;
				// 			default: break;
				// 		}
				// 		resultObj = resultObj.nested;
				// 	}
				// },
				// priceGridFlatResult_carrier(){
				// 	let reco = this.priceGridFlatResult?.extra_info;
				// 	return reco ? reco + " ?" : "N/A";
				// },


				//Related ACADIA Invoices (note: this.rowData.invoices is an old-school Map-like object )
				amount_from_our_sales(){
					let total = 0;
					for (let invoiceNum in this.rowData.invoices){
						//TODO define behavior for missing
						let invoice = this.rowData.invoices[invoiceNum];
						console.log(invoice);
						if (invoice) total += invoice.price;
					}
					return total;
				},				
				weight_from_our_sales(){					
					let total = 0;					
					for (let invoiceNum in this.rowData.invoices){
						let invoice = this.rowData.invoices[invoiceNum];
						if (invoice) total += invoice.weight;
					}
					return total;
				},

				
				// Comparison columns
				weight_delta(){
					return this.weight_from_our_sales - this.rowData.totalWeight;
				},
			    assessWeightOK(){
					return new Assessment(this.rowData.shipComment, (this.weight_delta > 0) ? LEVEL_OK : LEVEL_BAD, this.weight_delta);
				},
				weightOKclass(){
					return _generic_OKclass(this.assessWeightOK.level, true);
				},


				rowData_sumDetailAmount(){
					return 4444;
				},
	
				
				estimatedAmount_delta(){
					return this.priceGridResult.amount - this.rowData.totalAmount;
				},	
				assessTheirAmountOK(){
					return new Assessment("TODO tiré de nos calculs", (this.amount_from_our_sales) ? LEVEL_OK : LEVEL_BAD, this.estimatedAmount_delta);
				},

				theirAmountOKclass(){
					return _generic_OKclass(this.assessTheirAmountOK.level, true);
				},

				
				margin(){
					return this.amount_from_our_sales - this.rowData.totalAmount;
				},	
				assessOurMarginOK(){
					return new Assessment("TODO à voir", (this.margin > 0) ? LEVEL_OK : LEVEL_BAD, this.margin);
				},
				ourMarginOKclass(){
					return _generic_OKclass(this.assessOurMarginOK.level, true);
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
		<tr v-show="assessWeightOK.level <= hideWeightOKAbove
		       && assessTheirAmountOK.level <= hideTheirAmountOKAbove
		       && assessOurMarginOK.level <= hideOurMarginOKAbove"
		 @click="highlighted = !highlighted" :class="{'highlighted':highlighted}">
		 	<td>
				<div>{{ rowData.id }}</div>
			</td>
		 	<td>
				<div :title="rowData.article.pricegridPath">{{ rowData.article.articlePath }}</div>
			</td>
		 	<td>
				<div>{{ rowData.carrierInvoiceNum }}</div>
			</td>
			<td>
				<div @click="debug_PricingSystem"><datedisplay-day :value="rowData.carrierInvoiceDate"></datedisplay-day></div>
			</td>
			<td>
				<div>{{ rowData.carrierOrderNum }}</div>
			</td>
			<td>
				<div><datedisplay-day :value="rowData.carrierOrderDate"></datedisplay-day></div>
			</td>
			<td>
				<div>{{ rowData.shipCustomerLabel }}</div>
			</td>
			<td>
				<div>{{ rowData.shipCountry }}</div>
			</td>
			<td>
				<div>{{ rowData.shipZipcode }}</div>
			</td>
			<td>
				<div> extracted_zone </div>
			</td>
			<td>
				<div class="text-truncate" :title="rowData.internalReference">
					{{ rowData.internalReference }}
				</div>
			</td>
			<td class="erp-ref">
				<invoices-map :value="rowData.invoices"></invoices-map>
			</td>

			<td>
				<div>{{ rowData.parcelCount }}</div>
			</td>


			<td>
				<div>{{ weight_from_our_sales }}</div>
			</td>
			<td>
				<div :title="'Demandés: '+ rowData.reqTotalWeight ">{{ rowData.totalWeight }}</div>
			</td>
			<td>
				<div :title="assessWeightOK.msg" :class="weightOKclass">{{ assessWeightOK.cellValue }}</div>
			</td>

			<td>
				<div :title="rowData_sumDetailAmount">{{ rowData.totalAmount}}</div>
			</td>
			<td>
				{{ priceGridResult.amount }}
			</td>
			<td>
				<div :title="assessTheirAmountOK.msg" :class="theirAmountOKclass">{{ assessTheirAmountOK.cellValue }}</div>
			</td>

			<td>
				{{ amount_from_our_sales }}
			</td>
			<td>
				<div :title="assessOurMarginOK.msg" :class="ourMarginclass">{{ assessOurMarginOK.cellValue }}</div>
			</td>


<%--
			<td class="cust">
				<div v-if="rowData.customer">
					<div v-if="rowData.customer.tags.includes('inactive')">
						{{ rowData.customerRef }}
						<i role="button" class="bi bi-activity" title="Réactiver" @click="activateCustomer(rowData.customerRef)"></i>
					</div>
					<link-to-grid v-else url="../customers" attr="erpReference" :value="rowData.customerRef"></link-to-grid>
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
				<div>
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
<td>
	<div>{{ priceGridFlatResult_zone }}</div>
</td>
<td>
	<div :title="rowData_truncatedWeight" >{{ rowData.weight }}</div>
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

			--%>

		</tr>
	</script>

	<script type="text/javascript">
		var InvoiceMapRenderer = {
			props: {
				value: Object
			},
			template: "
				<ul v-for="">
					<li></li>
				</ul>
			"
		};
	invoices_from_our_sales(){
		let str = "";
		for (let invoiceNum in this.rowData.invoices){
			str += "\n* " + invoiceNum + " : ";
			
			let invoice = this.rowData.invoices[invoiceNum];
			if (invoice) str += invoice.id;
		}
		return str;					
	},
	
	
	
		var RevenueControlGrid = {
			props: {
				date:String
			},
			data() {
				return {
					dataList: [],

					hideWeightOKAbove: LEVEL_OK,
					hideTheirAmountOKAbove: LEVEL_OK,
					hideOurMarginOKAbove: LEVEL_OK,
				};
			},
			watch:{
				date:{
					immediate: true,
					handler(v){
						this.$emit("rowCount", null);
						if (!v) return; // fail silently for empty dates

						let startDate = new Date(v);
						let endDate = new Date(v);
						endDate.setMonth(startDate.getMonth() + 1);

						let resource_uri = "transport-purchase?start-date="+ startDate.toLocaleDateString() + "&end-date=" + endDate.toLocaleDateString();
						axios_backend.get(resource_uri)
						.then(response => {
							this.dataList = response.data;
							this.$emit("rowCount", this.dataList.length);
/*
							for (let row of this.dataList){
								// prepare user inputs
								if (!row.userInputs){
									row.userInputs = {};
								} else {
									row.$userInputs$price_MAIN_override = row.userInputs.price_MAIN_override;
									row.$userInputs$carrier_override = row.userInputs.carrier_override;
								}
							}
*/
						})
						.catch(error => {
							showAxiosErrorDialog(error);
						});
					}
				},
			},
			components:{
				"grid-row": RevenueControlGridRow,
			},
			computed:{

				hideWeightOKAboveclass(){
					return _filterBtn_OKclass(this.hideWeightOKAbove);
				},
				hideTheirAmountAboveclass(){
					return _filterBtn_OKclass(this.hideTheirAmountOKAbove);
				},
				hideOurMarginOKAboveclass(){
					return _filterBtn_OKclass(this.hideOurMarginOKAbove);
				},
			},
			methods: {
				clearFilters(){
					this["hideWeightOKAbove"] =
					this["hideTheirAmountOKAbove"] =
					this["hideOurMarginOKAbove"] = LEVEL_OK;
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
					<th data-bs-toggle="tooltip" title="ID système (caché)">
						<div>ID</div>
					</th>
					<th data-bs-toggle="tooltip" title="Transporteur/Produit">
						<div>Produit</div>
					</th>
					<th data-bs-toggle="tooltip" title="Numéro de facture Transporteur">
						<div>N° de facture</div>
					</th>
					<th data-bs-toggle="tooltip" title="Date de facture Transporteur">
						<div>Date de facture</div>
					</th>
					<th data-bs-toggle="tooltip" title="Numéro de récépissé (commande ACADIA)">
						<div>N° récépissé</div>
					</th>
					<th data-bs-toggle="tooltip" title="Date de récépissé (commande ACADIA)">
						<div>Date récépissé</div>
					</th>

					<th data-bs-toggle="tooltip" title="Nom du destinataire">
						<div>Destinataire</div>
					</th>
					<th class="cust" data-bs-toggle="tooltip" title="Pays de l'adresse d'expédition">
						<div>Pays</div>
					</th>
					<th class="cust lbl" data-bs-toggle="tooltip" title="Code postal de l'adresse d'expédition">
						<div>CP</div>
					</th>
					<th data-bs-toggle="tooltip" title="Zone géographique tarifaire (spécfique à la grille du Transporteur)">
						<div>Zone</div>
					</th>

					<th data-bs-toggle="tooltip" title="Référence Client sur l'étiquette d'expédition (= numéro(s) de facture ACADIA)">
						<div>Référence interne</div>
					</th>
					<th data-bs-toggle="tooltip" title="Factures ACADIA correspondantes">
						<div>Factures ACADIA</div>
					</th>

					<th data-bs-toggle="tooltip" title="Nombre de colis (issu de la facture Transporteur)">
						<div>Colis</div>
					</th>


					<th data-bs-toggle="tooltip" title="Total des poids sur les factures X3">
						<div>Poids ACADIA </div>
					</th>
					<th data-bs-toggle="tooltip" title="Poids noté sur la facture Transporteur (dans la bulle d'aide, le poids déclaré par ACADIA si présent)">
						<div>Poids Transporteur</div>
					</th>
					<th data-bs-toggle="tooltip" title="Écart de Poids (= poids ACADIA - poids Transp.)">
						<div>Δ Poids</div>
						<i @click="cycleFilter('WeightOK')" role="button" :class="hideWeightOKAboveclass"></i>
					</th>


					<th data-bs-toggle="tooltip" title="Montant TTC noté sur la facture Transporteur">
						<div>Prix Transporteur</div>
					</th>
					<th data-bs-toggle="tooltip" title="Notre estimation du montant, par application de la grille tarifaire Transporteur">
						<div>Estim. Transporteur</div>
					</th>
					<th data-bs-toggle="tooltip" title="Écart de prix (= prix ACADIA - prix Transp.)">
						<div>Δ Prix estimé</div>
						<i @click="cycleFilter('TheirAmountOK')" role="button" :class="hideTheirAmountOKAboveclass"></i>
					</th>

					<th data-bs-toggle="tooltip" title="Total des montants de factures X3">
						<div>Prix ACADIA </div>
					</th>
					<th data-bs-toggle="tooltip" title="Écart de prix (= prix ACADIA - prix Transp.)">
						<div>Marge ACADIA</div>
						<i @click="cycleFilter('OurMarginOK')" role="button" :class="hideOurMarginOKAboveclass"></i>
					</th>
<%--
					<th class="salesrep" data-bs-toggle="tooltip" title="Commercial ayant réalisé la vente">
						<div>Commercial</div>
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
--%>
				</tr>
			</thead>
			<tbody>
				<TransitionGroup name="list">
				<grid-row v-for="rowData in dataList" :key="rowData.id" :rowData="rowData"
				  :hide-weightOK-above = "hideWeightOKAbove"
				  :hide-theirAmountOK-above = "hideTheirAmountOKAbove"
				  :hide-ourMarginOK-above = "hideOurMarginOKAbove"
				  @filter-by-customer-label="filterByCustomerLabel"
				></grid-row>
				</TransitionGroup>
			</tbody>
		</table>
	</script>

	<script type="module">
		/* shared state for the page */
		const app = Vue.createApp({
			provide(){
				return {
					"priceGrids": this.carrierPriceGrids,
					LEVEL_NULL, LEVEL_BAD, LEVEL_WARN, LEVEL_OK, COUNT_LEVELS
				};
			},
			data(){
				return {
					ctrlDate: this.init_ctrlDate(),
					dataRowCount : null,

					carrierPriceGrids: [],
				};
			},
			methods:{
				init_ctrlDate(){
					let storedDate = localStorage.getItem("controls/costs/ctrlDate");
					return storedDate ?? Datepicker.currentDate();
				},
				loadRef_allCarrierGrids(){
					axios_backend.get("price-grids?tag=Transporteur")
					.then(response => {
						this.carrierPriceGrids.push(... response.data);
						for (let pg of this.carrierPriceGrids) {
							this.loadRef_allVersionsOfGrid(pg);
						}
					}).catch(error => {
						showAxiosErrorDialog(error);
					});
				},
				loadRef_allVersionsOfGrid(pg){
					axios_backend.get("price-grids/" + pg.id +"/versions?published-at="+ this.ctrlDate)
					.then(response => {
						let versionsMetaList = response.data;
						for (let pgv of versionsMetaList) {
							this.loadRef_contentOfGridVersion(pgv);
						}
						pg["#versions"] = versionsMetaList;
					});
				},
				loadRef_contentOfGridVersion(pgv){
					axios_backend.get("price-grids/" + pgv.priceGrid.id +"/versions/" + pgv.id + "/jsonContent")
					.then(response => {
						let system = new PricingSystem();
						system.fromJSON(response.data);
						pgv["#system"] = system;
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
					console.debug("shared ready TODO");
					return true;
				}
			},
			watch:{
				ctrlDate: {
					handler(v){
						localStorage.setItem("controls/costs/ctrlDate", v);
						// this.loadRef_MainPricingSystem(v);
						// this.loadRef_OtherPricingSystem(v);
					},
					immediate: true
				},
			},
			created(){
				this.loadRef_allCarrierGrids();
			}
		});

		app.component("override-signal", {
			template:"<span class=\"text-warning position-absolute top-0 end-0 me-1 opacity-75 pe-none\">⚠️</span>"
			//template:"<i class=\"text-warning bi bi-exclamation-octagon-fill position-absolute top-0 end-0 me-1 opacity-75 pe-none\"></i>"
		});
		app.component("invoice-map", InvoiceMapRenderer);


		app.component("datepicker-month", Datepicker_Month);
		app.component("audit-info", AuditingInfoRenderer);

		app.component("link-to-grid", LinkToGrid);
		app.component("datedisplay-day", Datedisplay_Day);
		app.component("revenue-control-grid", RevenueControlGrid);
		app.mount('#app');
	</script>
</body>



</html>
