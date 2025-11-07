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

	<style>

		/* Some table column styling */
		table#customer-grid tr td.mandatory-col {
			background-color: rgb(255, 245, 245);
		}

		table#customer-grid div.validation li::marker {
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
		<entity-data-grid id="customer-grid" resource-name="Liste de Clients" resource-uri="customers" identifier="id" :config="customerGridConfig"></entity-data-grid>
	</div>

	<!-- =========================================================== -->
	<!-- =============== Vue components ============================ -->


	<script type="module">

		/* shared state for the page */
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
								editor: "editor-customer-tags",
								descriptionIcon : "exclamation-diamond",
								description: "Description complémentaire, notamment utilisé pour le Contrôle Quotidien du Transport"
							},
							{
								name: "description",
								label: "Description",
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
						selectRowAction: "none"
					}
				};
			}


		});


		// specific cell renders/editors as VueJS components
		var systemTags = ["Grand Compte"]; //TODO système multi-groupes

		var EditorCustomerTags = {
			props: ['modelValue'],
			emits: ['update:modelValue'],
			computed: {
				editValue: {
					get() {return this.modelValue},
					set(value) {this.$emit('update:modelValue', value)}
				}
			},
			data(){
				return {
					systemTags
				}
			},
			template: `<text-tags-component :editable="true" v-model="editValue" :selectables="systemTags"/>`
		};
		var RendererCustomerTags = {
			extends: EditorCustomerTags,
			template: `<text-tags-component :editable="false" v-model="editValue" :selectables="systemTags"/>`
		};

		app.component("text-tags-component", TextTagsComponent);
		app.component("editor-customer-tags", EditorCustomerTags);
		app.component("renderer-customer-tags", RendererCustomerTags);

		app.component("renderer-auditing-info", AuditingInfoRenderer_IconWithPopover);


		app.component("entity-data-grid", EntityDataGrid);
		app.mount('#app');
	</script>

</body>



</html>
