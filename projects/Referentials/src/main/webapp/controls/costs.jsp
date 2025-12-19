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
		/** Table styling */
		table#costs-control-grid > thead > tr > th > div {
			height: 3em;
		}

		table#costs-control-grid > thead > tr > th,
		table#costs-control-grid > tbody > tr > td {
			position: relative; /* for signal icons overlay */
			padding-left: 0.3em;
			padding-right: 0.4em;
		}

		table#costs-control-grid td.intern-ref > div {
			width: 8em;
		}

		table#costs-control-grid  th.weight,
		table#costs-control-grid  td.weight {
			background-color: rgb(230, 255, 255);
		}
		table#costs-control-grid  th.costs,
		table#costs-control-grid  td.costs {
			background-color: rgb(255, 255, 230);
		}
		table#costs-control-grid  th.margin,
		table#costs-control-grid  td.margin {
			background-color: rgb(255, 230, 255);
		}

		table#costs-control-grid  td.weight.computed > div,
		table#costs-control-grid  td.costs.computed > div,
		table#costs-control-grid  td.margin.computed > div {
			padding: 0.1em 0.3em;
			font-weight: bold;
		}
		table#costs-control-grid  td.costs.comment > div,
		table#costs-control-grid  td.margin.comment > div {
			width: 7em;
		}

		table#costs-control-grid select,
		table#costs-control-grid input,
		table#costs-control-grid textarea {
			background-color: #ffffff80;
		}

		table#costs-control-grid  td.comment textarea {
			min-width: 6em;
			field-sizing: content;
		}
		table#costs-control-grid td.weight.name > div[role="button"] {
			padding-left: 0.4em;<%-- closer text align with the edit version (html select) --%>
		}

		table.detailed td {
			border: solid 1px black;
			padding: 0 0.5em;
		}

		table#costs-control-grid td.num,
		table.detailed td.num {
			text-align: end;
		}

	</style>
</head>

<body>
	<%@ include file="/WEB-INF/includes/body-inc/bs-confirmDialog.jspf" %>

	<div id="app" class="container-fluid d-flex flex-column vh-100">
		<div class="overflow-scroll" >
			<h2>Contrôle mensuel des factures Transporteur</h2>
			<div class="d-flex justify-content-between align-items-end">
				<div class="d-flex h-50 align-items-baseline mt-1">
					Période : <datepicker-month v-model="ctrlDate"></datepicker-month>
					<button class="btn btn-sm bi bi-funnel btn-secondary ms-2" @click="clearGridFilters"></button>

					<div v-if="dataRowCount" class="mx-2">{{ dataRowCount}} lignes</div>
					<a role="button" class="bi bi-sort-up-alt" @click="clearGridSorts"></a>
				</div>
			</div>
			<costs-control-grid v-if="sharedReady" ref="gridRoot"
			  :date="ctrlDate" :view-articles="activeGroup?.articles"
			  @row-count="dataRowCountChange" @articles-changed="updateProductGroups"></costs-control-grid>
		</div>

		<ul class="nav nav-pills">
			<li v-for="group of productGroups" class="nav-item">
				<a class="nav-link" :class="{active: isGroupActive(group)}" href="#" @click="selectGroup(group)">{{ group.name }}</a>
			</li>
		</ul>
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




		var CostsControlGridRow = {
			inject: ["priceGrids",
			  "LEVEL_NULL", "LEVEL_BAD", "LEVEL_WARN", "LEVEL_OK", "COUNT_LEVELS"],
			props: ["rowData",
					"hideWeightOKAbove",
					"hideTheirAmountOKAbove",
					"hideOurMarginOKAbove"
			],
			computed: {
				rowData_shortArticle(){
					let pgpath_items = /^(.*?)\/(.*)$/.exec(this.rowData.article.articlePath);
					let companyName = pgpath_items[1]; //Note : see how RowImporter build articlePaths using "ARTICLE_COMPANY"
					let articleRelativePath = pgpath_items[2];
					return articleRelativePath;
				},
				priceGridResult(){
					let pgpath_items = /^(.*?)\/(.*)$/.exec(this.rowData.article.pricegridPath);
					let dbGridName = pgpath_items[1]; // database entity PriceGrid name (home of a list of PriceGridVersion, each containing a JS PricingSystem...)
					let jsGridName = pgpath_items[2]; // entry key for a PricingGrid JS instance inside a PricingSystem JS object (a tab in the grid-edit.jsp).

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
 				priceGridFlatResult(){
					return PricingSystem.summarizeResult(this.priceGridResult);
				},

				priceGridFlatResult_zone(){
					//TODO NAM Q&D
					let resultList = this.priceGridResult;
					for (let resultObj of resultList) {
						if (resultObj?.gridCell?.coords?.zone) {
							return resultObj?.gridCell?.coords?.zone;
						}
					}
				},


				//Related ACADIA Invoices (note: this.rowData.invoices is an old-school Map-like object )
				amount_from_our_sales(){
					let total = 0;
					for (let invoiceNum in this.rowData.invoices){
						let invoice = this.rowData.invoices[invoiceNum];
						total += invoice?.price;
					}
					return total;
				},
				weight_from_our_sales(){
					let total = 0;
					for (let invoiceNum in this.rowData.invoices){
						let invoice = this.rowData.invoices[invoiceNum];
						total += invoice?.weight;
					}
					return total;
				},
				comments_from_our_sales(){
					let firstComment;
					let skippedCount = 0;
					for (let invoiceNum in this.rowData.invoices){
						let invoice = this.rowData.invoices[invoiceNum];

						let comment = "";
						if (invoice?.userInputs?.carrierOK_comment)
							comment += "🚛 " + invoice.userInputs.carrierOK_comment + "\n";
						if (invoice?.userInputs?.amountOK_comment)
							comment += "💵 " + invoice.userInputs.amountOK_comment + "\n";

						if (comment) {
							if (firstComment) {
								skippedCount++;
							} else {
								firstComment = comment;
							}
						}
					}


					if (firstComment && skippedCount){
						firstComment += ` [et \${skippedCount} autre(s)]`;
					}
					return firstComment ?? "✏️" ;
				},


				// Comparison columns
				weight_delta(){
					return this.weight_from_our_sales - this.rowData.totalWeight;
				},
			    assessWeightOK(){
					return new Assessment("TODO à voir",
					  (this.weight_delta > 0) ? LEVEL_OK : LEVEL_BAD,
					  this.weight_delta);
				},
				weightOKclass(){
					return _generic_OKclass(this.assessWeightOK.level, true);
				},



				estimatedAmount_delta(){
					return this.priceGridResult.amount - this.rowData.totalAmount;
				},
				assessTheirAmountOK(){
					let level = (this.estimatedAmount_delta > 0) ? LEVEL_OK : LEVEL_BAD;

					if (this.rowData.userInputs.theirAmountOK_override)
						level = this.rowData.userInputs.theirAmountOK_override;

					return new Assessment("TODO à voir", level,	this.estimatedAmount_delta);
				},
				theirAmountOKclass(){
					return _generic_OKclass(this.assessTheirAmountOK.level, true);
				},

				rowData_totalAmount_detailed(){// html popover
					let details = this.rowData.detailAmounts;

					let all_keys = Object.keys(details);
					const std_keys = ["Transport", "Surcharge Carburant", "Eco-participation", "TVA"];
					let missing_keys = all_keys.filter(k => !std_keys.includes(k));

					let str = "";
					for (let key of std_keys.concat(missing_keys)) {
						//Note : "Options" is a sub-total, should never have been imported as sub-article... if only we were confident about importing *all* options :/
						if (key == "Options") continue;
						str += "<tr><td>" + key + "</td><td class=\"num\">" + (details[key] ?? "N/A") + "</td></tr>";
					}
					return "<table class='detailed'>" + str +"</table>";
				},

				margin(){
					let m = this.amount_from_our_sales - this.rowData.totalAmount;
					this.rowData["#margin"] = m; // horrible border effect to make this calculation available to parent component (for sorting, for ex.)
					return m;
				},
				assessOurMarginOK(){
					let level = (this.margin > 0) ? LEVEL_OK : LEVEL_BAD;

					if (this.rowData.userInputs.ourMarginOK_override)
						level = this.rowData.userInputs.ourMarginOK_override;

					return new Assessment("TODO à voir", level, this.margin);
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

				},
				"rowData.invoices":{
					handler(newV, oldV){
						if (newV._v_lock != oldV._v_lock) {
							// post-update reload, skip save
						} else {
							this.saveRowData();
						}
					},
					deep: true
				},
			
			},
			methods: {
				renderNumber,

				saveRowData(){
					let rowDataClone = deepClone(this.rowData);

					// clean the "hard to track" useless overrides (like checkboxes)
					if (rowDataClone.userInputs.b2c_override == rowDataClone.b2c)
						delete rowDataClone.userInputs.b2c_override;

					axios_backend.put("transport-purchase/" + this.rowData.id, rowDataClone)
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
						deepClone(this.priceGridFlatResult), // PricingSystem flattened result, not necessarily used
						deepClone(this.priceGridResult) // PricingSystem complete result, not necessarily used
					);
				},

				cycleOKLevels(ptyName){
					ptyName += "OK_override";

 					if (!this.rowData.userInputs[ptyName]) this.rowData.userInputs[ptyName] = 0;
					this.rowData.userInputs[ptyName] ++;
					this.rowData.userInputs[ptyName] %= COUNT_LEVELS;
				},

				init_userInputs_comment(ev, ptyName){
					ptyName += "OK_comment";

					this.rowData["$userInputs$" + ptyName] = this.rowData.userInputs[ptyName];
					if (typeof this.rowData["$userInputs$" + ptyName] == "undefined"){
						this.rowData["$userInputs$" + ptyName] = " "; // will be cleared by the builtin trim
					}

					const parentCell = ev.target.closest("td");
					this.$nextTick(()=>{
						let input = parentCell.getElementsByTagName("textarea")[0]
						input.focus();
						input.select();
					});
				},

				validate_userInputs_comment(ptyName){
					ptyName += "OK_comment";

					if (this.rowData["$userInputs$" + ptyName].trim() == "")
						delete this.rowData["$userInputs$" + ptyName];

					if (this.rowData["$userInputs$" + ptyName] == this.rowData.userInputs[ptyName]){
						// unchanged
					} else {
						// trigger save
						this.rowData.userInputs[ptyName] = this.rowData["$userInputs$" + ptyName];
					}
				},



				clickPopover(e){
					var popover = bootstrap.Popover.getInstance(e.target);
					if (popover) {
						popover.dispose();
					} else {
						popover = bootstrap.Popover.getOrCreateInstance(e.target, {title:"Détail", "sanitize": false, "html": true});
						popover.show();
					}
				}
			},


			template: '#CostsControlGridRow-template'
		};
	</script>

	<script type="text/x-template" id="CostsControlGridRow-template">
		<tr v-show="assessWeightOK.level <= hideWeightOKAbove
		       && assessTheirAmountOK.level <= hideTheirAmountOKAbove
		       && assessOurMarginOK.level <= hideOurMarginOKAbove">
		 	<td>
				<div>{{ rowData.id }}</div>
			</td>
		 	<td>
				<div :title="'Grille appliquée : ' + rowData.article.pricegridPath">{{ rowData_shortArticle }}</div>
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
				<div>
					<link-to-grid url="../customers" attr="erpReference" :value="rowData.customerErpReference"></link-to-grid>
				</div>
			</td>
			<td>
				<div>{{ rowData.shipCountry }}</div>
			</td>
			<td>
				<div>{{ rowData.shipZipcode }}</div>
			</td>
			<td>
				<div> {{ priceGridFlatResult_zone }} </div>
			</td>
			<td class="intern-ref">
				<div class="text-truncate" :title="rowData.internalReference">
					{{ rowData.internalReference }}
				</div>
			</td>

			<td>
				<invoice-map v-model="rowData.invoices"></invoice-map>
			</td>

			<td class="num">
				<div>
					{{ rowData.parcelCount }}
				</div>
			</td>


			<td class="weight num">
				<div>{{ renderNumber(weight_from_our_sales) }}</div>
			</td>
			<td class="weight num">
				<div :title="'Déclaré par ACADIA: '+ rowData.reqTotalWeight ">
					<span v-if="rowData.shipComment" :title="rowData.shipComment">ℹ️</span>
					{{ renderNumber(rowData.totalWeight) }}
				</div>
			</td>
			<td class="weight num computed">
				<div :title="assessWeightOK.msg" :class="weightOKclass">
					{{ renderNumber(assessWeightOK.cellValue, 2) }}
				</div>
			</td>


			<td class="costs num">
				{{ renderNumber(priceGridResult.amount) }}
			</td>
			<td class="costs num">
				<div @click.stop="clickPopover" :data-bs-content="rowData_totalAmount_detailed">
					{{ renderNumber(rowData.totalAmount) }}
					<detailed-signal />
				</div>
			</td>
			<td class="costs num computed">
				<div :class="theirAmountOKclass">{{ renderNumber(assessTheirAmountOK.cellValue, 2) }}</div>
			</td>
			<td class="costs comment">
				<div :class="theirAmountOKclass" class="position-relative">
					<textarea rows="1"  v-if="rowData.$userInputs$theirAmountOK_comment"
					            v-model.lazy="rowData.$userInputs$theirAmountOK_comment"
					  @keyup.esc="$event.target.blur()"
					  @blur="validate_userInputs_comment('theirAmount')">
					</textarea>
					<div v-else role="button" @click="init_userInputs_comment($event, 'theirAmount')">
						✏️
					</div>
					<div class="position-absolute bottom-0 end-0" role="button" @click="cycleOKLevels('theirAmount')">
						🔃
					</div>
					<override-signal v-if="rowData.userInputs.theirAmountOK_override" />
				</div>
			</td>


			<td class="margin num">
				{{ renderNumber(amount_from_our_sales) }}
			</td>
			<td class="margin num computed">
				<div :title="assessOurMarginOK.msg" :class="ourMarginOKclass">
					{{ renderNumber(assessOurMarginOK.cellValue, 2) }}
				</div>
			</td>
			<td class="margin comment">
				<div :class="ourMarginOKclass" class="position-relative">
					<textarea rows="1"  v-if="rowData.$userInputs$ourMarginOK_comment"
					            v-model.lazy="rowData.$userInputs$ourMarginOK_comment"
					  @keyup.esc="$event.target.blur()"
					  @blur="validate_userInputs_comment('ourMargin')">
					</textarea>
					<div v-else role="button" @click="init_userInputs_comment($event, 'ourMargin')">
						{{ comments_from_our_sales }}
					</div>
					<div class="position-absolute bottom-0 end-0" role="button" @click="cycleOKLevels('ourMargin')">
						🔃
					</div>
					<override-signal v-if="rowData.userInputs.ourMarginOK_override" />
				</div>
			</td>
		</tr>
	</script>

	<script type="text/javascript">
		var CostsControlGrid = {
			props: {
				date:String,
				viewArticles: Array
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

							let articles = {};
							for (let row of this.dataList){
								// prepare user inputs
								if (!row.userInputs){
									row.userInputs = {};
								} else {
									row["$userInputs$theirAmountOK_comment"] = row.userInputs["theirAmountOK_comment"];
									row["$userInputs$ourMarginOK_comment"] = row.userInputs["ourMarginOK_comment"];
								}

								// collect distinct present Articles
								articles[row.article.articlePath] = row.article;
							}

							this.$emit("articlesChanged", articles);
						})
						.catch(error => {
							showAxiosErrorDialog(error);
						});
					}
				},
			},
			components:{
				"grid-row": CostsControlGridRow,
			},
			computed:{

				hideWeightOKAboveclass(){
					return _filterBtn_OKclass(this.hideWeightOKAbove);
				},
				hideTheirAmountOKAboveclass(){
					return _filterBtn_OKclass(this.hideTheirAmountOKAbove);
				},
				hideOurMarginOKAboveclass(){
					return _filterBtn_OKclass(this.hideOurMarginOKAbove);
				},
			},
			methods: {
				sortByAttr(propertyName, direction){
					this.dataList.sort((a,b) => {
						let aVal = a[propertyName];
						if (typeof aVal == "number" && isNaN(aVal))
							aVal = Number.POSITIVE_INFINITY; // positive because of the specific interest we have here for the negatives
						else
							aVal = aVal ?? "";

						let bVal = b[propertyName];
						if (typeof bVal == "number" && isNaN(bVal))
							bVal = Number.POSITIVE_INFINITY; // positive because of the specific interest we have here for the negatives
						else
							bVal = bVal ?? "";

						if (aVal > bVal)
							return direction;
						else if (aVal < bVal)
							return -direction;
						else
							return 0; // to keep it stable
					});
				},

				isRowViewed(rowData){
					//return this.viewArticles.some(a => a.articlePath == rowData.article.articlePath);
					return this.viewArticles.includes(rowData.article.articlePath);
				},
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
				}
			},
			mounted(){
				const tooltipTriggerList = this.$refs.rootElement.querySelectorAll('[data-bs-toggle="tooltip"]');
				const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));
			},

			template: '#CostsControlGrid-template'
		};
	</script>

	<script type="text/x-template" id="CostsControlGrid-template">
		<table id="costs-control-grid" class="table table-bordered table-sm table-striped table-hover" ref="rootElement">
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
					<th data-bs-toggle="tooltip" title="Numéro client, déduit des factures rattachées">
						<div>Code client</div>
					</th>

					<th data-bs-toggle="tooltip" title="Pays de l'adresse d'expédition">
						<div>Pays</div>
					</th>
					<th data-bs-toggle="tooltip" title="Code postal de l'adresse d'expédition">
						<div>CP</div>
					</th>
					<th data-bs-toggle="tooltip" title="Zone géographique tarifaire (spécfique à la grille du Transporteur)">
						<div>Zone</div>
					</th>

					<th class="intern-ref" data-bs-toggle="tooltip" title="Référence Client sur l'étiquette d'expédition (= numéro(s) de facture ACADIA)">
						<div>Référence interne</div>
					</th>
					<th data-bs-toggle="tooltip" title="Factures ACADIA correspondantes">
						<div>Factures ACADIA</div>
					</th>

					<th data-bs-toggle="tooltip" title="Nombre de colis (issu de la facture Transporteur)">
						<div>Colis</div>
					</th>


					<th class="weight" data-bs-toggle="tooltip" title="Total des poids sur les factures X3">
						<div>Poids ACADIA </div>
					</th>
					<th class="weight" data-bs-toggle="tooltip" title="Poids noté sur la facture Transporteur (dans la bulle d'aide, le poids déclaré par ACADIA si présent). Si présent, ℹ️ signale un commentaire du transporteur.">
						<div>Poids Facturé</div>
					</th>
					<th class="weight" data-bs-toggle="tooltip" title="Écart de Poids (= poids ACADIA - poids Transp.)">
						<div>Δ Poids</div>
						<i @click="cycleFilter('WeightOK')" role="button" :class="hideWeightOKAboveclass"></i>
					</th>

					<th class="costs" data-bs-toggle="tooltip" title="Notre estimation du montant, par application de la grille tarifaire Transporteur">
						<div>Estim. ACADIA</div>
					</th>
					<th class="costs" data-bs-toggle="tooltip" title="Montant TTC noté sur la facture Transporteur. Cliquer pour afficher un détail.">
						<div>Prix Facturé</div>
					</th>
					<th colspan="2"
					  class="costs computed" data-bs-toggle="tooltip" title="Écart de prix (= prix ACADIA - prix Transp.)">
						<div>Δ Prix estimé</div>
						<i @click="cycleFilter('TheirAmountOK')" role="button" :class="hideTheirAmountOKAboveclass"></i>
					</th>

					<th class="margin" data-bs-toggle="tooltip" title="Total des montants de factures X3">
						<div>Prix ACADIA </div>
					</th>
					<th colspan="2"
					  class="margin computed" data-bs-toggle="tooltip" title="Écart de prix (= prix ACADIA - prix Transp.)">
						<div>Marge ACADIA
							<a role="button" class="bi bi-sort-numeric-up" @click="sortByAttr('#margin', +1)"></a>
						</div>
						<i @click="cycleFilter('OurMarginOK')" role="button" :class="hideOurMarginOKAboveclass"></i>
					</th>
				</tr>
			</thead>
			<tbody>
				<TransitionGroup name="list">
				<template v-for="rowData in dataList">
					<grid-row v-if="isRowViewed(rowData)"
					  :key="rowData.id" :rowData="rowData"
					  :hide-weightOK-above = "hideWeightOKAbove"
					  :hide-theirAmountOK-above = "hideTheirAmountOKAbove"
					  :hide-ourMarginOK-above = "hideOurMarginOKAbove"
					></grid-row>
				</template>
				</TransitionGroup>
			</tbody>
		</table>
	</script>

	<script type="module">
		var InvoiceMapComponent = {
			props: {
				modelValue: Object, //	Map-like object, key="invoice Number" and value="serialized TransportSalesHeader"
				modelModifiers: Object, //	modelModifiers: capture and ignore
			},
			emits: ['update:modelValue'],
			computed: {
				arrayValue: {
					get() {
						console.info("GET");
						let res = [];
						if (this.modelValue){
							let keys = [...Object.keys(this.modelValue)];
							keys.sort();
							for (let key of keys){
								res.push({"num": AcadiaX3.shortInvoiceNumber(key), "obj" : this.modelValue[key]});
							}
						}
						if (res.length == 0){
							res.push({"num": "", "obj" : null});
						}
						return res;
					},
					set(v) {
						console.info("SET", v);
						let res= {};
						for (let item of v){
							let invNumber = AcadiaX3.restoreLongInvoiceNumber(item["num"]);
							res[invNumber] = item["obj"];
						}
						this.$emit('update:modelValue', res);
					},
				}
			},
			methods:{
				addEntry(){
					this.arrayValue.push({"num":"", "obj":null});
					this.arrayValue = this.arrayValue; // that "useless" line triggers the setter
				},
				removeEntry(index){
					this.arrayValue.splice(index, 1);
					this.arrayValue = this.arrayValue; // that "useless" line triggers the setter
				}
			},
			template:
			`<table class="detailed">
				<tr v-for="(item, index) in arrayValue">
					<td :class="{linked: !!item['obj']}">
						<input v-model="item['num']"></input>
					</td>
					<td>
						<button v-if="index == 0" @click="addEntry">+</button>
						<button v-else         @click="removeEntry(index)">-</button>
					</td>
				</tr>
			</table>`
		};



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

					productGroups: [],
					activeGroup: null,
				};
			},
			methods:{
				init_ctrlDate(){
					let storedDate = localStorage.getItem("controls/costs/ctrlDate");
					return storedDate ?? Datepicker.currentDate();
				},

				// tab navigation based on "product groups"
				isGroupActive(group){
					return this.activeGroup?.name == group?.name;
				},
				selectGroup(group){
					this.activeGroup = group;
				},

				// load PriceGrids of all carriers (TODO can we be more specific ?...)
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

				// exchange with Grid component
				clearGridFilters(){
					this.$refs.gridRoot.clearFilters();
				},
				clearGridSorts(){
					this.$refs.gridRoot.sortByAttr('id', +1);
				},
				dataRowCountChange(rc){
					this.dataRowCount = rc;
				},
				updateProductGroups(articles){
					let invertedMap = {};
					for (let article of Object.values(articles)){
						if (!invertedMap[article.pricegridPath]) invertedMap[article.pricegridPath] = [];
						invertedMap[article.pricegridPath].push(article.articlePath); // or .push(article) if you really need the full obj
					}
					let newProductGroups = [];
					for (let pricegridPath of Object.keys(invertedMap)){
						let articles = invertedMap[pricegridPath];
						newProductGroups.push({name : pricegridPath, articles});
					}
					this.productGroups = newProductGroups;

					if (this.productGroups.length > 0){
						this.activeGroup = this.productGroups[0];
					} else {
						this.activeGroup = null;
					}
				}
			},
			computed:{
				sharedReady(){ // almost a reactivity hack
					let pgloaded = 0;
					for (let pg of this.carrierPriceGrids){
						if (!pg["#versions"]) continue;
						for(let pgv of pg["#versions"]){
							pgloaded ++;
						}
					}
					return pgloaded > 0;
				}
			},
			watch:{
				ctrlDate: {
					handler(v){
						localStorage.setItem("controls/costs/ctrlDate", v);
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
		app.component("detailed-signal", {
			template:"<i class=\"text-primary bi bi-diagram-3-fill position-absolute top-0 start-0 me-1 opacity-50 pe-none\"></i>"
		});

		app.component("invoice-map", InvoiceMapComponent);

		app.component("datepicker-month", Datepicker_Month);

		app.component("link-to-grid", LinkToGrid);
		app.component("datedisplay-day", Datedisplay_Day);
		app.component("costs-control-grid", CostsControlGrid);
		app.mount('#app');
	</script>
</body>



</html>
