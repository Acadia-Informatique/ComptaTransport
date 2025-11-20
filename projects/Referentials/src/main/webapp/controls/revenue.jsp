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
	<script type="text/javascript">
		class PricedObject {
			constructor(weight, country, zip, carrier, isB2C, isHN, isInteg){
				this.weight = weight;
				this.country = country;
				this.zip = zip;
				this.carrier = carrier; // TODO transcode / resolve to obj ?
				this.isB2C = isB2C;
				this.isHN = isHN;
				this.isInteg = isInteg;
			}
			getPPGRawCoordinates(){
				let departement = (this.country=="FR" && this.zip &&  this.zip.length==5) ? this.zip.substring(0,2) : "00";
				return {
						poids : this.weight,
						// poidsEntier: Math.ceil(this.weight),
 						// poidsVolumique: Math.max(this.poids,
						//   (this.size_length * this.size_width * this.size_height) / 5000 // poids volumique d'après la fiche export
						// ),

						pays: this.country, // TODO lookup ISO 3166-1 alpha-2 or alpha-3 codes
						departement,
						tailleHN : this.isHN ? "Oui" : "Non",
						nbColis : 1, // TODO maybe get this info, or remove it from grids
						transporteur100: this.carrier, // TODO transcode again ?
						market: this.isB2C ? "BTC" : "BTB",
						integration: this.isInteg ? "Oui" : "Non"
				};
			}
		}
	</script>



	<style>
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
		var RevenueControlGridRow = {
			inject: ['pricingSystem', 'reflist_carriers'],
			props: {
				rowData:Object
			},
			computed: {
				rowData_shortInvoice(){ return AcadiaX3.shortInvoiceNumber(this.rowData.invoice)},
				rowData_carrierObj() {
					return this.reflist_carriers.get(this.rowData.carrier);
				},
				priceGridResult(){
					let pricedObject = new PricedObject (
						this.rowData["weight"],
						this.rowData["country"],
						this.rowData["zip"],
						this.rowData["carrier"],
						this.rowData["b2c"],
						false, //this.isHN = isHN;
						false//this.isInteg = isInteg;
					);

					return this.pricingSystem.applyGrid("Toutes livraisons", pricedObject);
				},


			},


			template: '#RevenueControlGridRow-template'
		};
	</script>

	<script type="text/x-template" id="RevenueControlGridRow-template">
		<tr>
			<td class="position-sticky">
				<div>{{ rowData_shortInvoice }}</div>
			</td>
			<td>
				<div>{{ rowData.order }}</div>
			</td>
			<td>
				<div v-if="rowData.customer">
					<link-to-grid url="../customers" attr="erpReference" :value="rowData.customerRef"></link-to-grid>
				</div>
				<div v-else>{{ rowData.customerRef }}</div>
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
				<div>{{ rowData.b2c ? "BTC" : "" }}</div>
			</td>

			<td class="carrier">
				<div>{{ rowData.carrier }}  -> {{ rowData_carrierObj.groupName }}</div>
			</td>
			<td class="carrier computed">
				<div>{{ priceGridResult?.extra_info }}</div>
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
				<div :title="JSON.stringify(priceGridResult)"> {{ priceGridResult?.amount }}</div>
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
				};
			},
			computed:{
				resourceUri(){
					return this.date
					  ? "transport-sales?start-date="+ this.date
					  : null;
				}
			},
			watch:{
				resourceUri(v){
					if (!v) return; // fail silently for empty dates
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
			components:{
				"grid-row": RevenueControlGridRow,
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
						<div>Options</div>
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
				<grid-row v-for="rowData in dataList" :key="rowData.id"
				  :rowData="rowData"></grid-row>
			</tbody>
		</table>
	</script>

	<script type="module">

		/* shared state for the page */
		const app = Vue.createApp({
			provide(){
				return {
					"pricingSystem": Vue.reactive(this.pricingSystem),
					"reflist_carriers": this.reflist_carriers,
				};
			},
			data(){
				return {
					ctrlDate: Datepicker.currentDate(),
					pricingSystem: new PricingSystem(),
					reflist_carriers: new Map()
				};
			},
			watch:{
				ctrlDate(v){
					let pgv_metadata_uri = "price-grids/*/versions/latest-of?grid-name=Acadia&published-at=" + v;
					axios_backend.get(pgv_metadata_uri)
					.then(response => {
						let pgv_metadata = response.data;

						if (!pgv_metadata || !pgv_metadata.id)
							throw new Error("Aucune grille publiée à la date demandée");

						if (this.pricingSystem
						  && this.pricingSystem["#pgv_metadata_id"] && this.pricingSystem["#pgv_metadata_id"] == pgv_metadata["id"]
  						  && this.pricingSystem["#pgv_metadata_v_lock"] && this.pricingSystem["#pgv_metadata_v_lock"] == pgv_metadata["_v_lock"]
						) {
							return; // pricingSystem already OK
						} // else proceed


						let PRICE_GRID_ID = pgv_metadata.priceGrid.id;
						let PRICE_GRID_VERSION_ID = pgv_metadata.id;
						let dataUri =`price-grids/\${PRICE_GRID_ID}/versions/\${PRICE_GRID_VERSION_ID}/jsonContent`;

						axios_backend.get(dataUri)
						.then(response => {
							this.pricingSystem.fromJSON(response.data);
							// marking for caching
							this.pricingSystem["#pgv_metadata_id"] = pgv_metadata["id"];
							this.pricingSystem["#pgv_metadata_v_lock"] = pgv_metadata["_v_lock"];
						})
						.catch(error => {
							alert_dialog("Récupération de la grille tarifaire ACADIA", error.message);
						});
					})
					.catch(error => {
						//showAxiosErrorDialog(error);
						alert_dialog("Récupération de la grille tarifaire ACADIA (entête)", error.message);
					});
				}
			},
			created(){
				axios_backend.get("carriers")
				.then(response => {
					for (let carrier of response.data){
						this.reflist_carriers.set(carrier.name, carrier);
					}
				});
			}
		});

		// specific cell renders/editors as VueJS components
		app.component("link-to-grid", LinkToGrid);

		app.component("datedisplay-day", Datedisplay_Day);
		app.component("datepicker-day", Datepicker_Day);


		app.component("revenue-control-grid", RevenueControlGrid);
		app.mount('#app');
	</script>
</body>



</html>
