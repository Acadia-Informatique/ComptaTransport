<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

	<title>Grilles tarifaires</title>

	<%@ include file="/WEB-INF/includes/header-inc/client-stack.jspf" %>

	<%@ include file="/WEB-INF/includes/header-inc/vue-entityDataGrid.jspf" %>
	<%@ include file="/WEB-INF/includes/header-inc/vue-entityAttributeComponents.jspf" %>
  </head>
  <body>
	<style>

		/* Some table column styling */
		table#pricegrid-grid div.validation li::marker {
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

	<div id="app" class="container-fluid">
		<div class="row">
			<div class="col-7 vh-100 overflow-auto">
				<entity-data-grid id="pricegrid-grid" resource-name="Liste de Grilles tarifaires" resource-uri="price-grids" identifier="id" :config="pricegridGridConfig"></entity-data-grid>
			</div>
			<div class="col-5 vh-100 overflow-auto">
				<template v-if="selectedPriceGridId">
					<entity-data-grid id="pricegridversion-grid" resource-name="Versions" :resource-uri="'price-grids/'+ selectedPriceGridId +'/versions'" identifier="id" :config="pricegridversionGridConfig"></entity-data-grid>
				</template>
				<div v-else>
					Sélectionnez une grille pour en voir les versions.
				</div>
			</div>
		</div>
	</div>


	<!-- =========================================================== -->
	<!-- =============== Vue components ============================ -->

	<!-- ========== (some) component templates ============== -->







	<!-- ========== component logic ============== -->
	<script type="module">

		/* shared state for the page */
		const app = Vue.createApp({
			provide(){
				return {
					pgid : Vue.computed(()=> this.selectedPriceGridId)
				}
			},
			data(){
				return {
					selectedPriceGridId : 0,

					pricegridGridConfig : {
						defaultNewEntity : {
  							"name": "",
							"description": "",
							"tags": ["interne"]
						},
						columns: [
							{
								name: "id",
								label: "ID",
								editable: false,
								visible: false,
							},
							{
								name: "name",
								label: "Nom",
								mandatory: true,
								format: {pattern:/^.{0,32}$/, errorMsg:"Longueur max: 32"},
								description:"Nom de la grille (par ex. BTB, BTC, nom du transporteur)"
							},
							{
								name: "tags",
								label: "Tags",
								renderer: "renderer-pricegrid-tags",
								editor: "editor-pricegrid-tags",
								descriptionIcon : "exclamation-diamond",
								description: "Qualification technique complémentaire"
							},
							{
								name: "description",
								label: "Description",
								renderer: "textarea",
								editor: "textarea",
								format: {pattern:/^(?:.|\n|\r){0,256}$/, errorMsg:"Longueur max: 256"},
								description: "Description libre"
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
								label: "",
								width: "50px",
								sortable: false,
								editable: false,
								renderer: "renderer-auditing-info"
							},
						],
						inferColumns: true,
						confirmDelete: true,
						selectRowAction: (entity)=>{
							this.selectedPriceGridId = entity["id"];
						}
					},
					pricegridversionGridConfig : {
						defaultNewEntity : {
							"version": "YYYY-MM",
							"published_date": null,
						},
						columns: [
							{
								name: "id",
								label: "ID",
								editable: false,
								visible: false,
							},
							{
								name: "version",
								label: "Version",
								mandatory: true,
								format: {pattern:/^[\w-]{0,64}$/, errorMsg:"64 caractères max., parmi a..z, 0..9, -, _"},
								description:"Identifiant de version (ordre par défaut)"
							},
							{
								name: "published_date",
								label: "Publié le",
								//renderer: TODO date picker
								//editor: TODO date picker, publishing tool ?
								description: "Date de publication (libre, peut être dans le futur)"
							},
							{
								name: "id",
								label: "Éditer la grille",
								editable: false,
								visible: true,
								renderer: "pricegrid-edit-launcher",
								editor:   "pricegrid-edit-launcher"
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
								label: "",
								width: "50px",
								sortable: false,
								editable: false,
								renderer: "renderer-auditing-info"
							},
						],
						inferColumns: true,
						confirmDelete: true
					},

				};
			}


		});


		// specific cell renders/editors as VueJS components
		var systemTags = ["interne", "transporteur"];

		var EditorPriceGridTags = {
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
		var RendererPriceGridTags = {
			extends: EditorPriceGridTags,
			template: `<text-tags-component :editable="false" v-model="editValue" :selectables="systemTags"/>`
		};

		app.component("text-tags-component", TextTagsComponent);
		app.component("editor-pricegrid-tags", EditorPriceGridTags);
		app.component("renderer-pricegrid-tags", RendererPriceGridTags);

		app.component("renderer-auditing-info", AuditingInfoRenderer_IconWithPopover);

		app.component("pricegrid-edit-launcher", {
			props: ['modelValue'],
			inject: ['pgid'],
			template: `<a :href="'grid-edit.jsp?pgid='+pgid+'&version='+modelValue" class="btn btn-primary">Éditer la grille</a>`
		});


		app.component("entity-data-grid", EntityDataGrid);
		app.mount('#app');
	</script>

</body>



</html>
