<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

	<title>Clients "Forfait Transport"</title>

	<%@ include file="/WEB-INF/includes/header-inc/client-stack.jspf" %>

	<%@ include file="/WEB-INF/includes/header-inc/vue-entityDataGrid.jspf" %>
	<%@ include file="/WEB-INF/includes/header-inc/vue-entityAttributeComponents.jspf" %>
	<%@ include file="/WEB-INF/includes/header-inc/vue-entityTextTagsComponents.jspf" %>
	<%@ include file="/WEB-INF/includes/header-inc/vue-datepickers.jspf" %>

	<script src="${libsUrl}/customer.js"></script>

	<style>

		/* Some table column and row styling */
		table#customer-grid tr td.mandatory-col {
			background-color: rgb(255, 245, 245);
		}

		table#customer-grid div.validation li::marker {
		  content: "\00274C"; /* emoji "Red X" */
		}

		table#customer-grid tr.row-highlight td {
			background-color: yellow;
		}

		/* Table row align : fixed height for pretty anything in this screen: */

		/* - table "tops" */
		table#customer-grid caption,
		div.caption-like {
			box-sizing: border-box;
			height:4rem;
			max-height:4rem;
			overflow:hidden;
		}

		/* - table rows : */
		table#customer-grid tr:not(.row-editing) th > div,
		table#shipPref-grid tr:not(.row-editing) th > div {
			height:4rem;
			max-height:4rem;
			overflow:hidden;
			margin: 0;
			padding: 0.1rem  0.25rem;
		}
		table#customer-grid tr:not(.row-editing) td > div,
		table#shipPref-grid tr:not(.row-editing) td > div  {
			height:2.5rem;
			max-height:2.5rem;
			overflow:hidden;
			margin: 0;
			padding: 0.1rem  0.25rem;
		}
	</style>

</head>

<body>
	<%@ include file="/WEB-INF/includes/body-inc/bs-confirmDialog.jspf" %>

	<div id="app" class="d-flex col-12">
		<div class="col-6">
			<entity-data-grid id="customer-grid" resource-name="Liste de Clients" resource-uri="customers" identifier="id" :config="customerGridConfig"
			  @view-list="mainListChanged" @editing="mainEditingChanged"
			  class="table-striped"
			  v-if="sharedReady"></entity-data-grid>

		</div>


		<div class="col-6">
			<div class="caption-like d-flex justify-content-between align-items-end" >
				<ul class="nav nav-tabs">
					<li class="nav-item">
						<a href="#" class="nav-link" :class="{'active': isTab('shipPref')}" @click="setTab('shipPref')">Préf. Transport</a>
					</li>
					<li class="nav-item">
						<a href="#" class="nav-link" :class="{'active': isTab('amounts')}" @click="setTab('amounts')">Montants</a>
					</li>
				</ul>
				<div class="amount-selector">
					TODO forfaits validés Y/N

					<input type="radio" id="amt-revenue" value="amt-revenue" v-model="amountMode" />
					<label for="amt-revenue">Revenu</label>
					<input type="radio" id="amt-cost" value="amt-cost" v-model="amountMode" />
					<label for="amt-cost">Charges</label>
					<input type="radio" id="amt-margin" value="amt-margin" v-model="amountMode" />
					<label for="amt-margin">Marge</label>
				</div>
			</div>
			<div v-if="isTab('shipPref')" class="ms-1">
				<customer-ship-preferences id="shipPref-grid"
				  :customer-list="customerList" :editing-customer="editingCustomer"></customer-ship-preferences>
			</div>
			<div v-else-if="isTab('amounts')" class="ms-1">
				table de montants
			</div>

		</div>
	</div>




	<!-- =========================================================== -->
	<!-- =============== Vue components ============================ -->
	<script type="text/x-template" id="Customer_ShipPreferences-template">
	<table class="table table-bordered table-sm table-striped" style="table-layout: fixed" ref="rootElement">
		<thead class="shadow sticky-top">
			<tr>
				<th data-bs-toggle="tooltip" title="Date initiale d'application">
					<div>Depuis</div>
				</th>
				<th data-bs-toggle="tooltip" title="Transports exclusifs (càd portant le tag Exclusif)">
					<div>Transp. par</div>
				</th>
				<th data-bs-toggle="tooltip" title="Grille tarifaire personnalisée">
					<div>Grille spécif.</div>
				</th>
				<th data-bs-toggle="tooltip" title="Complément tarifs personnalisés (ex. tarif réduit sur option B2C)">
					<div>Autres spécif.</div>
				</th>
				<th data-bs-toggle="tooltip" title="Tags de transporteurs préférés. Signalé quand présent sur le transporteur CHOISI, pour le justifier.">
					<div>Whitelist Transporteurs</div>
				</th>
				<th data-bs-toggle="tooltip" title="Tags de transporteurs à éviter. Signalé quand présent sur le transporteur RECOMMANDÉ, pour expliquer son éviction.">
					<div>Blacklist Transporteurs</div>
				</th>
				<th data-bs-toggle="tooltip" title="Informations d'audit sur les Préférences de Transport"
				  style="width:40px">
					<div>ℹ️</div>
				</th>
				<th data-bs-toggle="tooltip" title="Cliquer sur l'icône pour savoir ce qui motive la mention &quot;Franco&quot;."
				  style="width:8em">
					<div>Franco ?</div>
				</th>
				<th
				  style="width:8em">
					<div><datepicker-month v-model="shipPrefMonth"></datepicker-month></div>
				</th>
			</tr>
		</thead>
		<tbody>
			<TransitionGroup name="list">
			<tr v-for="customer in customerList" :key="customer['#key']"
			  :class="{'row-editing': isEditingRow(customer)}">

				<template v-if="isEditingRow(customer)">
					{{void(
						editingCustomer["#currPref"] = applicablePref(editingCustomer)
					)}}
					<template v-if="editingCustomer['#currPref']">
						<td>
							<div><datepicker-month v-model="editingCustomer['#currPref'].applicationDate"></datepicker-month> </div>
						</td>
						<td>
							<div><select multiple="true" v-model="editingCustomer['#currPref'].overrideCarriers">
								<option v-for="carrier in selectableCarriers.values()"
								  :value="carrier.name">
									{{ carrier.name }} <%-- {{ carrier.label }} --%>
								</option>
							</select></div>
						</td>
						<td>
							<div><entity-selector v-model="editingCustomer['#currPref'].overridePriceGrid"
								labelPty = "name"
								resource-name="Grilles tarifaires de port" resource-uri="price-grids?tag=Tarif+Spécial" identifier="id"
								:config="pricegridSelectorConfig" ></entity-selector></div>
						</td>
						<td>
							<div><renderer-shipPreferences-tags v-model="editingCustomer['#currPref'].tags"
							  editable ></renderer-shipPreferences-tags></div>
						</td>
						<td>
							<div><renderer-carrier-tags v-model="editingCustomer['#currPref'].carrierTagsWhitelist"
							  editable onlySelectables ></renderer-carrier-tags></div>
						</td>
						<td>
							<div><renderer-carrier-tags v-model="editingCustomer['#currPref'].carrierTagsBlacklist"
							  editable onlySelectables ></renderer-carrier-tags></div>
						</td>
						<td>
							<div><renderer-auditing-info v-model="editingCustomer['#currPref'].auditingInfo" ></renderer-auditing-info></div>
						</td>
					</template>
					<template v-else>
						<td colspan="7"><div><button class="btn btn-sm btn-primary" @click="initApplicablePref(editingCustomer)">Ajouter préférences spécifiques</button></div></td>
					</template>
					<td>
						<div>
							<icon-with-popover :model-value="assessZeroFee(editingCustomer)" data-bs-title="Franco de port"
							  icon="hand-thumbs-up-fill" icon-empty="hand-thumbs-down"/>
						</div>
					</td>
				</template>
				<template v-else>
					{{void(
						customer["#currPref"] = applicablePref(customer)
					)}}
					<template v-if="customer['#currPref']">
						<td>
							<div><datedisplay-month :value="customer['#currPref'].applicationDate" /></div>
						</td>
						<td>
							<div>
								<div v-for="carrierName in customer['#currPref'].overrideCarriers" class="text-truncate">
									{{ carrierName }}
								</div>
							</div>
						</td>
						<td>
							<div>{{ customer['#currPref'].overridePriceGrid?.name }}</div>
						</td>
						<td>
							<div><renderer-shipPreferences-tags v-model="customer['#currPref'].tags"></renderer-shipPreferences-tags></div>
						</td>
						<td>
							<div><renderer-carrier-tags v-model="customer['#currPref'].carrierTagsWhitelist" /></div>
						</td>
						<td>
							<div><renderer-carrier-tags v-model="customer['#currPref'].carrierTagsBlacklist" /></div>
						</td>
						<td>
							<div><renderer-auditing-info v-model="customer['#currPref'].auditingInfo" /></div>
						</td>
					</template>
					<template v-else>
						<td colspan="7"><div>...</div></td>
					</template>
					<td>
						<div>
							<icon-with-popover :model-value="assessZeroFee(customer)" data-bs-title="Franco de port"
							  icon="hand-thumbs-up-fill" icon-empty="hand-thumbs-down"/>
						</div>
					</td>
				</template>
				<td>
					<div v-if="monthlyAggShippingRevenue(customer)"
					  :class="monthlyAggShippingRevenue(customer)?.product=='MONTHLY' ? 'text-bg-success' : 'text-bg-warning'">
						{{ monthlyAggShippingRevenue(customer)?.amount }}
					</div>
					<div v-else>
						<input value="TODO"></input>
					</div>
				</td>
			</tr>
			</TransitionGroup>
		</tbody>
	</table>
	</script>

	<script type="text/javascript">
		var Customer_ShipPreferences = {
			props: {
				customerList:Array,
				editingCustomer: Object
			},
			data() {
				return {
					shipPrefMonth: Datepicker.currentMonth(),
					selectableCarrierTags: {},
					selectableCarriers: new Map(),
					pricegridSelectorConfig : {
						columns: [
							{
								name: "name",
								label: "Nom",
								description:"Nom de la grille (par ex. BTB, BTC, nom du transporteur)"
							},
							{
								name: "tags",
								label: "Tags",
								renderer: "renderer-pricegrid-tags",
								descriptionIcon : "exclamation-diamond",
								description: "Qualification technique complémentaire"
							},
							{
								name: "description",
								label: "Description",
								renderer: "textarea",
								description: "Commentaire libre"
							},
							{
								name: "auditingInfo",
								label: "ℹ️",
								width: "3em",
								sortable: false,
								editable: false,
								renderer: "renderer-auditing-info",
								description: "Informations d'audit"
							},
						],
						inferColumns: false
					},
					aggShippingRevenues: new Map()
				};
			},
			watch:{
				shipPrefMonth:{
					handler(v){
						this.aggShippingRevenues.clear();

						let startDate = v + ".0";
						let endDate = v + ".1";
						axios_backend.get(`customers/*/agg-shipping-revenues?start-date=\${startDate}&end-date=\${endDate}`)
						.then(response => {
							for (let agg of response.data){
								let custAggs = this.aggShippingRevenues.get(agg.customerId);
								if (!custAggs) { custAggs = []; }

								custAggs.push(agg);
								this.aggShippingRevenues.set(agg.customerId, custAggs); // should only be needed in case of new array, but with VueJS better be safe
							}
						});
					},
					immediate : true
				}
			},
			methods:{
				//TODO make each row a Vue Component ?
				applicablePref(customer){
					let returnVal = null;
					if (customer.shipPreferences){
						// sort by reverse order of applicationDate
						customer.shipPreferences.sort((a,b) => {
							const aVal = a.applicationDate;
							const bVal = b.applicationDate;
							return (aVal > bVal) ? -1 : +1; //applicationDate is supposedly unique
						});
						// pick most recent applicable
						for (let pref of customer.shipPreferences){
							if (pref.applicationDate <= this.shipPrefMonth){
								returnVal = pref;
								break;
							}
						}
					}
					return returnVal;
				},
				initApplicablePref(customer){
					if (!customer.shipPreferences) customer.shipPreferences = [];
					customer.shipPreferences.push({
						"applicationDate": this.shipPrefMonth, // so directly visible
						"tags": [],
						"carrierTagsBlacklist": [],
						"carrierTagsWhitelist": [],
						"overrideCarriers": [],
						"overridePriceGrid": null
					});
				},

				monthlyAggShippingRevenue(customer){
					return CustomerFunc.getMonthlyOne(this.aggShippingRevenues.get(customer.id));
				},

				assessZeroFee(customer){
					return CustomerFunc.assessZeroFee(false, customer, customer["#currPref"], this.aggShippingRevenues.get(customer.id), this.selectableCarriers);
				},



				isEditingRow(entity){
					return entity["#key"] == (this.editingCustomer ? this.editingCustomer["#key"] : null);
				},
			},
			created(){
				axios_backend.get("carriers")
				.then(response => {
					for (let carrier of response.data){
						this.selectableCarriers.set(carrier.name, carrier);
					}
				});
			},
			mounted(){
				const tooltipTriggerList = this.$refs.rootElement.querySelectorAll('[data-bs-toggle="tooltip"]');
				const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl))
			},
			template: '#Customer_ShipPreferences-template'
		};
	</script>


	<%-- Assemble app with main grid (left) --%>
	<script type="module">

		const app = Vue.createApp({
			data(){
				return {
					customerGridConfig : {
						defaultNewEntity : {
							"erpReference": "C00000",
							"label": "",
							"tags": []
						},
						columns: [
							{
								name: "id",
								label: "ID",
								editable: false,
								visible: false,
							},
							{
								name: "erpReference",
								label: "Référence ERP",
								insertable: true,
								updatable: false,
								mandatory: true,
								format: {pattern:/^[\w/-]{1,16}$/, errorMsg:"Jusqu'à 16 lettres et chiffres"},
								descriptionIcon : "key",
								description:"Numéro Client X3, à priori de la forme C00000"
							},
							{
								name: "label",
								label: "Libellé",
								mandatory: true,
								format: {pattern:/^.{0,64}$/, errorMsg:"Longueur max: 64"},
								description:"Libellé libre"
							},
							{
								name: "tags",
								label: "Tags",
								renderer: "renderer-customer-tags",
								editor: "renderer-customer-tags",
								descriptionIcon : "exclamation-diamond",
								description: "Description complémentaire, notamment utilisé pour le Contrôle Quotidien du Transport"
							},
							{
								name: "salesrep",
								label: "Commercial",
								//TODO editor: selector on SalesRep User...
								description: "Responsable du Compte client"
							},
							{
								name: "description",
								label: "Description",

								editor: "textarea",

								/* since we need fixed height here, in readonly mode...
								renderer: "textarea",
								format: {pattern:/^(?:.|\n|\r){0,256}$/, errorMsg:"Longueur max: 256"}, */
								description: "Commentaire libre"
							},
							{
								name: "shipPreferences",
								visible: false,
							},
							{
								name: "aggShippingRevenues",
								visible: false,
							},
							{
								name: "_v_lock",
								label: "(version)",
								editable: false,
								sortable: false,
								visible: false // show for debug
							},
							{
								name: "auditingInfo",
								label: "ℹ️",
								width: "3em",
								sortable: false,
								editable: false,
								renderer: "renderer-auditing-info",
								description: "Informations d'audit"
							},
						],
						inferColumns: true,
						confirmDelete: true,
						selectRowAction: "none",
						payloadProcessor: (entity)=>{
							if (entity.shipPreferences) {
								for (let pref of entity.shipPreferences){
									delete pref.auditingInfo;

									// keep only overridePriceGrid.id
									if (pref.overridePriceGrid){
										for (let attr in pref.overridePriceGrid){
											if (attr != "id") delete pref.overridePriceGrid[attr];
										}
									}
								}
							}
						}
					},
					customerList: [],
					editingCustomer: null,

					selectableTags: {},
					sharedPricegridTextTags: {},
					sharedCarrierTextTags: {},
					sharedShipPreferencesTags: {},

					activeTab: "shipPref",

					amountMode: "amt-margin",

				};
			},
			computed:{
				sharedReady(){ // almost a reactivity hack
					console.debug("shared ready");
					return Object.keys(this.selectableTags).length > 0
					&& Object.keys(this.sharedPricegridTextTags).length > 0
					&& Object.keys(this.sharedCarrierTextTags).length > 0;
				}
			},
			created(){
				CustomerTextTags.initSharedTags(this.selectableTags);
				PricegridTextTags.initSharedTags(this.sharedPricegridTextTags);
				CarrierTextTags.initSharedTags(this.sharedCarrierTextTags);

				// cf. controls/revenue.jsp for how these tags are used:
				this.sharedShipPreferencesTags["text-bg-warning"] = ["B2B: Franco", "B2C: tarif B2B"];
				this.sharedShipPreferencesTags["text-bg-primary"] = ["B2C: xxx €"]; //cf. B2C_tag_regex
			},
			provide(){
				return {
					sharedCustomerTextTags: this.selectableTags,
					sharedPricegridTextTags: this.sharedPricegridTextTags,
					sharedCarrierTextTags: this.sharedCarrierTextTags,
					sharedShipPreferencesTags : this.sharedShipPreferencesTags
				};
			},
			methods: {
				mainListChanged(list) {
					this.customerList = list;
				},
				mainEditingChanged(entity) {
					this.editingCustomer = entity;
				},

				isTab(tab){
					return this.activeTab == tab;
				},
				setTab(tab){
					this.activeTab = tab;
				},
			},

		});


		// specific cell renders/editors as VueJS components
		app.component("renderer-customer-tags", CustomerTextTags);
		app.component("renderer-carrier-tags", CarrierTextTags);
		app.component("renderer-pricegrid-tags", PricegridTextTags);
		app.component("renderer-shipPreferences-tags", {
			extends: _AbstractEntityTextTags,
			inject: {
				"selectables": { from: "sharedShipPreferencesTags"}
			}
		});


		app.component("renderer-auditing-info", AuditingInfoRenderer_IconWithPopover);

		app.component("entity-data-grid", EntityDataGrid);


		// Right side component 1
		app.component("customer-ship-preferences", Customer_ShipPreferences);

		// Misc. utility components
		app.component("datedisplay-month", Datedisplay_Month);
		app.component("datepicker-month", Datepicker_Month);
		app.component("icon-with-popover", IconWithPopover);
		app.component("entity-selector", EntitySelector);

		app.mount('#app');
	</script>

</body>



</html>
