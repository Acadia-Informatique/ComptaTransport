<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

	<title>Grilles tarifaires de port</title>

	<%@ include file="/WEB-INF/includes/header-inc/client-stack.jspf" %>

	<%@ include file="/WEB-INF/includes/header-inc/vue-entityDataGrid.jspf" %>
	<%@ include file="/WEB-INF/includes/header-inc/vue-entityAttributeComponents.jspf" %>

	<style>
		/* Custom styles for large devices (≥992px) */
		@media only screen and (min-width: 992px) {
			/* equivalent of lg-* versions of vh-100 and overflow-y */
			div.custom-lg-scrollcolumn {
				overflow-y: auto !important;
				height: 100vh !important;
			}
		}

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



		.p-datepicker-calendar-container {
			background-color: pink;

		}

	</style>

</head>

<body>
	<%@ include file="/WEB-INF/includes/body-inc/bs-confirmDialog.jspf" %>

	<div id="app" class="container-fluid">
		<div class="row">
			<div class="col-12 col-lg-5 custom-lg-scrollcolumn">
				<entity-data-grid id="pricegrid-grid"
				  resource-name="Grilles tarifaires de port" resource-uri="price-grids" identifier="id"
				  :config="pricegridGridConfig" class="table-hover"></entity-data-grid>
			</div>
			<div class="col-12 col-lg-7 custom-lg-scrollcolumn">
				<template v-if="selectedPriceGridId">
					<entity-data-grid id="pricegridversion-grid" resource-name="Versions" :resource-uri="'price-grids/'+ selectedPriceGridId +'/versions'" identifier="id" :config="pricegridversionGridConfig"></entity-data-grid>
				</template>
				<div v-else class="mt-5">
					Sélectionnez une grille pour en voir les versions.
				</div>
			</div>
		</div>
	</div>

	<!-- =========================================================== -->
	<!-- =============== Vue components ============================ -->

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
						selectRowAction: (entity)=>{
							this.selectedPriceGridId = entity["id"];
						}
					},
					pricegridversionGridConfig : {
						defaultNewEntity : {
							"version": "YYYY-MM",
							"publishedDate": null,
						},
						columns: [
							{
								// note : parent is fetched for other use cases.
								name: "priceGrid",
								visible: false
							},
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
								format: {pattern:/^.{0,64}$/, errorMsg:"Longueur max: 64"},
								description:"Identifiant de version (ordre par défaut)"
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
								name: "publishedDate",
								label: "Publié le",
								//renderer: TODO date picker
								//editor: TODO date picker, publishing tool ?
								description: "Date de publication (libre, peut être dans le futur)"
							},
							{
								name: "id",
								label: "Éditer",
								width: "150px",						
								renderer: "pricegrid-edit-launcher",
								editor: "none"
							},
							{
								name: "#uri",
								label: "Copie",
								width: "100px",
								renderer: "pricegrid-action-copy",
								editor: "none"
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
								editable: false,
								renderer: "renderer-auditing-info"
							},
						],
						inferColumns: true,
						confirmDelete: true,
						payloadProcessor: (entity)=>{
							delete entity.priceGrid;
						}
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
			props: ["modelValue"],
			inject: ["pgid"],
			template: `<a role="button" :href="'grid-edit.jsp?pgid='+pgid+'&pgvid='+modelValue" class="btn btn-primary bi bi-arrow-return-right">Éditer la grille</a>`
		});

		app.component("pricegrid-action-copy", {
			inject: ["pgid"],
			props: ["modelValue"],
			emits:["entities-changed"],
			methods:{
				responseHandler(response){
					if (response.status == 201){
						this.$emit('entities-changed');
					} else {
						let error = response; // since we don't like ;-)
 						error.message = "Statut HTTP attendu = 201 (Created)";
						error.code = "Error de copie";
						throw error;
					}
				}
			},
			components:{
				"client-button" : EntityActionClient,
				"param-field" : QueryParamComponent
			},
			template:
				`<client-button :resource-uri="modelValue + '/copy'" needs-params
				  btn-text="Copie" btn-icon="copy"
				  :success-callback="responseHandler">
					<param-field name="newVersion" placeholder="Version à créer" class="form-control form-control-sm" type="text"></param-field>
				</client-button>`
		});


		app.component("entity-data-grid", EntityDataGrid);

		app.mount('#app');
	</script>

</body>



</html>
