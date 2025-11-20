<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

	<title>Contrôle Quotidien Transport</title>

	<%@ include file="/WEB-INF/includes/header-inc/client-stack.jspf" %>

	<%@ include file="/WEB-INF/includes/header-inc/vue-datepickers.jspf" %>
	<%--
	@ include file="/WEB-INF/includes/header-inc/vue-entityAttributeComponents.jspf"
	--%>
	<style>
		/** Bootstrap global overrides */
		html {
		  font-size: 0.8em;
		}

		/** Table readability */
		th.price,
		td.price {
			background-color: pink;
		}
		th.carrier,
		td.carrier {
			background-color: cyan;
		}
	</style>

</head>

<body>
	<%@ include file="/WEB-INF/includes/body-inc/bs-confirmDialog.jspf" %>

	<div id="app">
		<h2>Contrôle quotidien des frais de transport facturés</h2>
		Date : <datepicker-day v-model="ctrlDate"></datepicker-day>

		<revenue-control-grid class="table-hover"
		  :date="ctrlDate"></revenue-control-grid>
	</div>

	<!-- =========================================================== -->
	<!-- =============== Vue components ============================ -->
	<script type="text/javascript">
		var RevenueControlGrid = {
			props: {
				date:String
			},
			data() {
				return {
					dataList: [],
				};
			},
			computed:{
				resourceUri(){
					return "transport-sales"
					+ "?start-date="+(this.date ?? "now")
				}
			},
			methods:{


			},

			watch:{
				resourceUri(v){
					axios_backend.get(v)
					.then(response => {
						this.dataList = response.data;

						// flattening of row.details
						for (let row of this.dataList){
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
			},
			mounted(){
				const tooltipTriggerList = this.$refs.rootElement.querySelectorAll('[data-bs-toggle="tooltip"]');
				const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl))
			},
			template: '#RevenueControlGrid-template'
		};
	</script>

	<script type="text/x-template" id="RevenueControlGrid-template">
		<table class="table table-bordered table-sm table-striped" ref="rootElement">
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
					<th data-bs-toggle="tooltip" title="Pays">
						<div>Pays</div>
					</th>
					<th data-bs-toggle="tooltip" title="Code postal">
						<div>CP</div>
					</th>
					<th data-bs-toggle="tooltip" title="Date de facture">
						<div>Date de facture</div>
					</th>
					<th data-bs-toggle="tooltip" title="Commercial">
						<div>Commercial</div>
					</th>
					<th data-bs-toggle="tooltip" title="Poids selon X3">
						<div>Poids</div>
					</th>
					<th data-bs-toggle="tooltip" title="Livraison en Drop/BTC">
						<div>B2C ?</div>
					</th>



					<th class="carrier" data-bs-toggle="tooltip" title="Choix transporteur par le commercial">
						<div>Transporteur choisi</div>
					</th>
					<th class="carrier computed" data-bs-toggle="tooltip" title="Transporteur recommandé pource client et par les grilles standard">
						<div>Transporteur reco</div>
					</th>

					<th class="price" data-bs-toggle="tooltip" title="detail">
						<div>Frais de port</div>
					</th>
					<th class="price" data-bs-toggle="tooltip" title="detail">
						<div>Supplém. BTC</div>
					</th>
					<th class="price" data-bs-toggle="tooltip" title="detail">
						<div>Option</div>
					</th>
					<th class="price" data-bs-toggle="tooltip" title="detail">
						<div>Option 2</div>
					</th>

					<th class="price" data-bs-toggle="tooltip" title="Montant total des frais de port payés, selon X3">
						<div>Total frais</div>
					</th>
					<th class="price computed" data-bs-toggle="tooltip" title="Transporteur recommandé pource client et par les grilles standard">
						<div>Prix reco</div>
					</th>
				</tr>
			</thead>
			<tbody>
				<tr v-for="rowData in dataList" :key="rowData.id">
					<td class="position-sticky">
						<div>{{ rowData.invoice }}</div>
					</td>
					<td>
						<div>{{ rowData.order }}</div>
					</td>
					<td>
						<div>{{ rowData.customer }}</div>
					</td>
					<td>
						<div>{{ rowData.customerLabel }}</div>
					</td>
					<td>
						<div>{{ rowData.country }}</div>
					</td>
					<td>
						<div>{{ rowData.zip }}</div>
					</td>
					<td>
						<div><datedisplay-day :value="rowData.date"></datedisplay-day></div>
					</td>
					<td>
						<div>{{ rowData.salesrep }}</div>
					</td>
					<td>
						<div>{{ rowData.weight }}</div>
					</td>
					<td>
						TODO B2C
					</td>

					<td class="carrier">
						<div>{{ rowData.carrier }}</div>
					</td>
					<td class="carrier computed">
						<div>TODO</div>
<%--
Transporteur reco selon grille tarifaire
 + préférences clients(override/whitelist/blacklist)
--%>

					</td>

					<td class="price">
						<div :title="rowData['P_MAIN']?.desc">{{ rowData['P_MAIN']?.price}}</div>					
					</td>
					<td class="price">
						<div :title="rowData['P_B2C']?.desc">{{ rowData['P_B2C']?.price}}</div>					
					</td>
					<td class="price">
						<div :title="rowData['P_OPT1']?.desc">{{ rowData['P_OPT1']?.price}}</div>					
					</td>
					<td class="price">
						<div :title="rowData['P_OPT2']?.desc">{{ rowData['P_OPT2']?.price}}</div>					
					</td>

					<td class="price">
						<div>{{ rowData.price }}</div>
					</td>
					<td class="price computed">
						<div>TODO</div>
					</td>
				</tr>
			</tbody>
		</table>
	</script>

	<script type="module">

		/* shared state for the page */
		const app = Vue.createApp({
			data(){
				return {
					ctrlDate: Datepicker.currentDate()
					//selectableTags : {}
				};
			},
			// provide(){
			// 	return {"sharedCarrierTextTags": this.selectableTags };
			// },
			// created(){
			// 	CarrierTextTags.initSharedTags(this.selectableTags)
			// }
		});

		// specific cell renders/editors as VueJS components
		//app.component("renderer-carrier-tags", CarrierTextTags);
		//app.component("renderer-auditing-info", AuditingInfoRenderer_IconWithPopover);

		app.component("datedisplay-day", Datedisplay_Day);
		app.component("datepicker-day", Datepicker_Day);


		app.component("revenue-control-grid", RevenueControlGrid);
		app.mount('#app');
	</script>
</body>



</html>
