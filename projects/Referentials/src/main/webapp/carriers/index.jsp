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
  </head>
  <body>
	<style>
		table#carrier-grid caption {
			caption-side: top;
    		font-size: 1.5em;
    		margin-left: 0.5em;
		}	

		table#carrier-grid thead {
		  	position: sticky;
			top: 0; /* Don't forget this, required for the stickiness */
			box-shadow: 0px 8px 10px 0px rgba(0, 0, 0, 0.4);
			z-index:3;
		}

		table#carrier-grid th.identifier-col {
			position: relative;
		}

		table#carrier-grid th.identifier-col::after {
			position: absolute;
			top: 2px; right: 5px;
			content: "\01F511"; /* emoji "Key" */
		}

		table#carrier-grid tr td.mandatory-col {
			background-color: rgb(255, 255, 250);
		}

		table#carrier-grid div.validation li::marker {
		  content: "\00274C"; /* emoji key */
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
		<entity-data-grid id="carrier-grid" resource-name="Liste de Transporteurs" resource-uri="carriers" identifier="name" :config="carrierGridConfig"></entity-data-grid>
	</div>

	<!-- =========================================================== -->
	<!-- =============== Vue components ============================ -->

	<!-- ========== (some) component templates ============== -->







	<!-- ========== component logic ============== -->
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
								format: {pattern:/^.{0,32}$/, errorMsg:"Longueur max: 32"}
							},
							{
								name: "label",
								label: "Libellé",
								mandatory: true,
								format: {pattern:/^.{0,64}$/, errorMsg:"Longueur max: 64"}
							},
							{
								name: "shortName",
								label: "Lib. court",
								width: "8em",
								format: {pattern:/^.{0,16}$/, errorMsg:"Longueur max: 16"}
							},
							{
								name: "groupName",
								label: "Groupe de contrôle",
								width: "8em",
								format: {pattern:/^.{0,32}$/, errorMsg:"Longueur max: 32"}
							},
							{
								name: "tags",
								label: "Tags",
								renderer: "renderer-carrier-tags",
								editor: "editor-carrier-tags"
							},
							{
								name: "warningMessage",
								label: "Message d'alerte",
								format: {pattern:/^.{0,64}$/, errorMsg:"Longueur max: 64"}
							},
							{
								name: "description",
								label: "Description",
								width: "10%",
								renderer: "textarea",
								editor: "textarea",
								format: {pattern:/^.{0,256}$/, errorMsg:"Longueur max: 256"}
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
								label: "(audit)",			
								width: "50px",
								sortable: false,
								editable: false,
								renderer: "renderer-auditing-info"
							},
						],
						inferColumns: true,
						confirmDelete: true
					}
				};
			}


		});


		// specific cell renders/editors as VueJS components
		var systemTags = ["zero-fee", "virtual"];

		var EditorCarrierTags = {
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
		var RendererCarrierTags = {
			extends: EditorCarrierTags,
			template: `<text-tags-component :editable="false" v-model="editValue" :selectables="systemTags"/>`
		};

		app.component("text-tags-component", TextTagsComponent);
		app.component("editor-carrier-tags", EditorCarrierTags);
		app.component("renderer-carrier-tags", RendererCarrierTags);

		app.component("renderer-auditing-info", AuditingInfoRenderer_IconWithPopover);


		app.component("entity-data-grid", EntityDataGrid);
		app.mount('#app');
	</script>

</body>



</html>
