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

	<style>

		/* Some table column styling */
		table#customer-grid tr td.mandatory-col {
			background-color: rgb(255, 245, 245);
		}

		table#customer-grid div.validation li::marker {
		  content: "\00274C"; /* emoji "Red X" */
		}


		/* Table row align : fixed height for prettyt anything in this screen: */

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
		}
		table#customer-grid tr:not(.row-editing) td > div,
		table#shipPref-grid tr:not(.row-editing) td > div  {
			height:3rem;
			max-height:3rem;
			overflow:hidden;
		}


		/** List animations */
		.list-move, /* apply transition to moving elements */
		.list-enter-active,
		.list-leave-active {
			transition: all 0.5s ease;
		}

		.list-enter-from,
		.list-leave-to {
			opacity: 0;
			transform: translateX(30px);
		}

		/* ensure leaving items are taken out of layout flow so that moving
		animations can be calculated correctly. */
		.list-leave-active {
			position: absolute;
		}
	</style>

</head>

<body>
	<%@ include file="/WEB-INF/includes/body-inc/bs-confirmDialog.jspf" %>

	<div id="app" class="d-flex col-12">
		<div class="col-6">
			<entity-data-grid id="customer-grid" resource-name="Liste de Clients" resource-uri="customers" identifier="id" :config="customerGridConfig"
			  @reorder="mainListChanged" @editing="mainEditingChanged"
			  class="table-striped"></entity-data-grid>

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
				<th data-bs-toggle="tooltip" title="Transporteurs exclusifs">
					<div>Transp. par</div>
				</th>
				<th data-bs-toggle="tooltip" title="Grille tarifaire personnalisée">
					<div>Grille</div>
				</th>
				<th data-bs-toggle="tooltip" title="Tags de transporteurs préférés">
					<div>Whitelist Transporteurs</div>
				</th>
				<th data-bs-toggle="tooltip" title="Tags de transporteurs à éviter">
					<div>Blacklist Transporteurs</div>
				</th>
				<th data-bs-toggle="tooltip" title="Informations d'audit sur les Préférences de Transport"
				  style="width:50px">
					<div>ℹ️</div>
				</th>
				<th>
					<div>Franco ?</div>
				</th>
				<th>
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
							<div><datepicker-month v-model="editingCustomer['#currPref'].applicationDate"/></div>
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
							<entity-selector v-model="editingCustomer['#currPref'].overridePriceGrid"
								labelPty = "name"
								resource-name="Grilles tarifaires de port" resource-uri="price-grids" identifier="id"
								:config="pricegridSelectorConfig" />
						</td>
						<td>
							<div><renderer-carrier-tags v-model="editingCustomer['#currPref'].carrierTagsWhitelist"
							  editable onlySelectables /></div>
						</td>
						<td>
							<div><renderer-carrier-tags v-model="editingCustomer['#currPref'].carrierTagsBlacklist"
							  editable onlySelectables /></div>
						</td>
						<td>
							<div><renderer-auditing-info v-model="editingCustomer['#currPref'].auditingInfo" /></div>
						</td>
					</template>
					<template v-else>
						<td colspan="6"><div><button @click="initApplicablePref(editingCustomer)">Ajouter préférences spécifiques</button></div></td>
					</template>
					<td>
						<div>
							<icon-with-popover :model-value="assessZeroFee(editingCustomer)" title="Franco de port"
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
						<td colspan="6"><div>...</div></td>
					</template>
					<td>
						<div>
							<icon-with-popover :model-value="assessZeroFee(customer)" title="Franco de port"
							  icon="hand-thumbs-up-fill" icon-empty="hand-thumbs-down"/>
						</div>
					</td>
				</template>
				<td>
					<div>Montant du jour</div>
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
								width: "50px",
								sortable: false,
								editable: false,
								renderer: "renderer-auditing-info",
								description: "Informations d'audit"
							},
						],
						inferColumns: false
					},
				};
			},
			watch(){
					// if (!entityList) return;
					// this.masterCustomerIds = entityList.map(customer => customer.id);

					// entityList.forEach(customer => {
					// 	if (customer.shipPreferences && customer.shipPreferences.length > 0) {
					// 		this.customerPreferences.set(customer.id, customer.shipPreferences[0]); // supposedly sorted by date DESC
					// 	} else {
					// 		this.customerPreferences.set(customer.id, {DUMMY: "DUMMY"});
					// 	}
					// });
			},
			methods:{
				//TODO make each row a Vue Component ?
				//TODO externalize applicablePref() and assessZeroFee() for reuse in Contrôle (but you ll need a full list of Carriers(=selectableCarriers))
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
						"carrierTagsBlacklist": [],
						"carrierTagsWhitelist": [],
						"overrideCarriers": [],
						"overridePriceGrid": null
					});
				},

				assessZeroFee(customer){
					let reasons = [];
					if (customer.tags.includes("Grand Compte")) {
						reasons.push(`Client "Grand Compte"`);
					}
				/*	let shipPreferences = customer["#currPref"];
					if (shipPreferences?.overrideCarriers?.length > 0){
						let areAllCarriersFree = shipPreferences.overrideCarriers
						.map(name => this.selectableCarriers.get(name))
						.every(c => c.tags.includes("Sans frais"));

						if (areAllCarriersFree){
							reasons.push(`Transports gratuits uniquement`);
						}
					}
*/
					return (reasons.length > 0) ? reasons : null;
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
								name: "description",
								label: "Description",

								/* since we need fixed height here...
								renderer: "textarea",
								editor: "textarea",
								format: {pattern:/^(?:.|\n|\r){0,256}$/, errorMsg:"Longueur max: 256"}, */
								description: "Commentaire libre"
							},
							{
								name: "shipPreferences",
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
								visible: false, /* table a bit too cramped */
								width: "50px",
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

					activeTab: "shipPref",

					amountMode: "amt-margin"
				};
			},
			created(){
				CustomerTextTags.initSharedTags(this.selectableTags);

				PricegridTextTags.initSharedTags(this.sharedPricegridTextTags);
				CarrierTextTags.initSharedTags(this.sharedCarrierTextTags);
			},
			provide(){
				return {
					sharedCustomerTextTags: this.selectableTags,
					sharedPricegridTextTags: this.sharedPricegridTextTags,
					sharedCarrierTextTags: this.sharedCarrierTextTags
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
