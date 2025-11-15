<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

	<title>Liste des transporteurs</title>

	<%@ include file="/WEB-INF/includes/header-inc/client-stack.jspf" %>

	<%@ include file="/WEB-INF/includes/header-inc/vue-entityDataGrid.jspf" %>
	<%@ include file="/WEB-INF/includes/header-inc/vue-entityAttributeComponents.jspf" %>
	<%@ include file="/WEB-INF/includes/header-inc/vue-entityTextTagsComponents.jspf" %>

	<style>

		/* Some table column styling */
		table#carrier-grid th.identifier-col::after {
			position: absolute;
			top: 2px; left: 5px;
			content: "\01F511"; /* emoji "Key" */
		}

		table#carrier-grid tr td.mandatory-col {
			background-color: rgb(255, 255, 200);
		}

		table#carrier-grid div.validation li::marker {
		  content: "\00274C"; /* emoji "Red X" */
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

	<div id="app">
		<entity-data-grid id="carrier-grid" resource-name="Liste de Transporteurs" resource-uri="carriers" identifier="name"
		  :config="carrierGridConfig" class="table-hover" ></entity-data-grid>
	</div>

	<!-- =========================================================== -->
	<!-- =============== Vue components ============================ -->


	<script type="module">

		/* shared state for the page */
		const app = Vue.createApp({
			data(){
				return {
					carrierGridConfig : {
						defaultNewEntity : {
  							"name": "",
  							"label": "",
							"shortName": "",
							"tags": []
						},
						columns: [
							{
								name: "name",
								label: "Nom",
								insertable: true,
								updatable: false,
								mandatory: true,
								format: {pattern:/^[\w/-]{1,32}$/, errorMsg:"Jusqu'à 32 lettres et chiffres"},
								description:"Identifiant du transporteur"
							},
							{
								name: "label",
								label: "Libellé",
								mandatory: true,
								format: {pattern:/^.{0,64}$/, errorMsg:"Longueur max: 64"},
								description:"Libellé libre"
							},
							{
								name: "shortName",
								label: "Lib. court",
								visible: false,
								format: {pattern:/^.{0,16}$/, errorMsg:"Longueur max: 16"},
								description: "(existe dans X3, probablement inutilisé)"
							},
							{
								name: "groupName",
								label: "Groupe de contrôle",
								width: "8em",
								format: {pattern:/^.{0,32}$/, errorMsg:"Longueur max: 32"},
								descriptionIcon : "exclamation-diamond",
								description: "Référence pour les Grilles Tarifaires, les Contrôles, etc."
							},
							{
								name: "tags",
								label: "Tags",
								renderer: "renderer-carrier-tags",
								editor: "renderer-carrier-tags",
								descriptionIcon : "exclamation-diamond",
								description: "Description complémentaire, notamment utilisé par le module Clients forfaits"
							},
							{
								name: "warningMessage",
								label: "Message d'alerte",
								format: {pattern:/^.{0,64}$/, errorMsg:"Longueur max: 64"},
								descriptionIcon : "exclamation-diamond",
								description: "Signale les Transporteurs problématiques, ce qui lève une alerte au niveau des contrôles."
							},
							{
								name: "description",
								label: "Description",
								width: "10%",
								renderer: "textarea",
								editor: "textarea",
								format: {pattern:/^(?:.|\n|\r){0,256}$/, errorMsg:"Longueur max: 256"},
								description: "Commentaire libre"
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
								width: "50px",
								sortable: false,
								editable: false,
								renderer: "renderer-auditing-info",
								description: "Informations d'audit"
							},
						],
						inferColumns: true,
						confirmDelete: true,
						selectRowAction: "edit"
					},
					selectableTags : {}
				};
			},
			provide(){
				return {"sharedCarrierTextTags": this.selectableTags };
			},
			created(){
				CarrierTextTags.initSharedTags(this.selectableTags)
			}
		});

		// specific cell renders/editors as VueJS components
		app.component("renderer-carrier-tags", CarrierTextTags);
		app.component("renderer-auditing-info", AuditingInfoRenderer_IconWithPopover);

		app.component("entity-data-grid", EntityDataGrid);
		app.mount('#app');
	</script>

</body>



</html>
