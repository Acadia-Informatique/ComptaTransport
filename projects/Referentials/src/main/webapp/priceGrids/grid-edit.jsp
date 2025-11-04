<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!doctype html><html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

	<title>Édition de Grille tarifaire Transport</title>

	<%@include file="/WEB-INF/includes/header-inc/client-stack.jspf"%>

	<%@ include file="/WEB-INF/includes/header-inc/vue-entityAttributeComponents.jspf" %>

	<script src="${libsUrl}/pricegrid.js"></script>

	<script type="text/javascript">
		"use strict";

		let params = new URL(document.location.toString()).searchParams;
		var PRICE_GRID_ID          = params.get("pgid");
		var PRICE_GRID_VERSION_ID  = params.get("pgvid");


		class CommandeALivrer {
			constructor( poids, codePostal){
				this.poids = poids;
				this.pays = "France";
				this.codePostal = codePostal;
				this.size_length = null;
				this.size_width = null;
				this.size_height = null;
				this.size_parcel_count = 1;
				this.transporteur100 = "";
				this.market = "BTB";
				this.isIntegration = false;
			}
			getPPGRawCoordinates(){
				let departement = (this.pays=="France" && this.codePostal &&  this.codePostal.length==5) ? this.codePostal.substring(0,2) : "00";
				return {
						poids : this.poids,
						poidsEntier: Math.ceil(this.poids),
						poidsVolumique: Math.max(this.poids,
						  (this.size_length * this.size_width * this.size_height) / 5000 // poids volumique d'après la fiche export
						),
						pays: this.pays, // TODO lookup ISO 3166-1 alpha-2 or alpha-3 codes
						departement,
						tailleHN :
							((this.size_length + 2*this.size_width + 2*this.size_height) > 300)
							|| (this.size_parcel_count > 10) ? "Oui" : "Non",
						nbColis : this.size_parcel_count ?? 1,
						transporteur100: this.transporteur100,
						market: this.market,
						integration: this.isIntegration ? "Oui" : "Non"
				};
			}
		}
	</script>

	<style>
		/** Bootstrap global overrides */
		.accordion {
			--bs-accordion-btn-color: black;
			--bs-accordion-btn-bg: rgb(32, 211, 194);
			--bs-accordion-active-color: white;
			--bs-accordion-active-bg: rgb(0, 0, 172);
		}

		/** General layout */
		#pricinggrids-builder {
			display: grid;
			grid-template-columns: auto;
			grid-template-rows: auto auto auto;
			grid-template-areas:
				"header"
				"sidebar"
				"main";
		}

		div#header-pane {
			grid-area: header;
		}
		div#tool-pane {
			grid-area: sidebar;
		}
		div#pricinggrid-pane {
			grid-area: main;
			scroll-behavior: smooth;
		}

		@media only screen and (min-width: 992px) { /* Custom styles for large devices (≥992px) */
			#pricinggrids-builder {
				display: grid;
				grid-template-columns: auto 25em;
				grid-template-rows: auto 1fr;
				grid-template-areas:
					"header sidebar"
					"main  sidebar";
				column-gap: 0.5em;
			}
			div#tool-pane {
				overflow-y: auto !important;
				height: 100vh;
			}
			div#pricinggrid-pane {
				overflow-y: auto !important;
				height: 85vh !important;
			}
			div#gridViewport {
				overflow-y: auto;
				height: 60vh;
			}
		}


		/** App specifics */
		.tooltip-pre {
			white-space: pre;
		}
		div#gridViewport {
			border: 3px inset grey;
			overflow-x: auto;
		}
		table.gridTable {
			--bs-border-color: rgb(80, 80, 80);
			--bs-border-width: 2px;
		}
		table.gridTable thead {
		  	position: sticky;
			top: 0; /* Don't forget this, required for the stickiness */
			box-shadow: 0px 10px 16px 0px rgba(0, 0, 0, 0.4);
			z-index:3;
		}

		table.gridTable th.gridHead {
			--bs-table-bg: rgb(246, 255, 164);

			position: sticky;
			left: 0; /* Don't forget this, required for the stickiness */
			/* box-shadow: 10px 0px 16px 0px rgba(0, 0, 0, 0.4); not showing ?... */
			z-index:2;
		}

		.gridCell, .gridHead {
			position: relative; /* for absolute children*/
		}

		.gridCell input.money-input {
			width:4.5em;
			border:1px dotted lightgrey;
			padding: 0.1em 0.2em;
			text-align:right;
		}
		.gridCell input.money-input:invalid {
			border:1px solid red ;
			background-color:pink ;
		}
		.gridCell .secondary {
			font-size: 80%;
		}
		.gridCell .quick-extra-info {
			position: absolute;
			top:10px; left:5px;
			color:rgba(119, 71, 9, 0.3);
			font-size: 1.5em;
			font-weight:bolder;
			line-height:1em;
			transform: rotate(10deg);
			pointer-events: none;
		}

		.hiddenFileImpExp {
			display: inline-block;
			width:1px;
			overflow: hidden;
			visibility: hidden;
		}

		/** Save button animation */
		.bi-floppy2-fill {
			transition: all 500ms;
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
	<%@include file="/WEB-INF/includes/body-inc/bs-confirmDialog.jspf"%>

	<div id="pricinggrids-builder" class="container-fluid">

		<div id="header-pane" class="d-flex flex-row justify-content-between align-items-center me-2">
			<a class="nav-link" href="./">&lt;&nbsp;Retour</a>

			<template v-if="pgv_metadata">
				<div class="d-flex flex-wrap align-items-center mx-3">
				
					<%--	
					<i v-if="needSaving" role="button" @click="apiPutJsonContent"
					  class="bi bi-floppy2-fill text-danger fs-1 me-2"></i>
					<i v-else
					  class="bi bi-floppy2-fill text-success fs-2 me-2"></i>
					... more obvious, but changed to a single "mutating" element, to allow animation
					--%>
					<i class="bi bi-floppy2-fill me-2" 
					  :role="needSaving ? 'button' : null"
					  @click="needSaving ? apiPutJsonContent() : null"
					  :class="needSaving ? ['text-danger','fs-1'] : ['text-success','fs-2']"></i>
					  
					<div class="fs-2 fw-bold me-2" ref="gridLabel">{{pgv_metadata.priceGrid.name}}</div>
					<div class="fs-4 me-2" ref="versionLabel">{{pgv_metadata.version}}</div>
					<text-tags v-model="pgv_metadata.priceGrid.tags"></text-tags>
				</div>

				<audit-info class="small text-nowrap" v-model="pgv_metadata.auditingInfo"></audit-info>
			</template>
		</div>

		<div id="tool-pane" class="accordion shadow pt-2">
			<div class="accordion-item">
				<h2 class="accordion-header">
					<button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#collapseOne" aria-expanded="true" aria-controls="collapseOne">
						Test frais livraison
					</button>
				</h2>
				<div id="collapseOne" class="accordion-collapse collapse show" data-bs-parent="#tool-pane">
					<div class="accordion-body">
						<pricingtest-form :ui_state="ui_state"></pricingtest-form>
					</div>
				</div>
			</div>
			<div class="accordion-item">
				<h2 class="accordion-header">
					<button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseTwo" aria-expanded="false" aria-controls="collapseTwo">
						Charger / Enregistrer
					</button>
				</h2>
				<div id="collapseTwo" class="accordion-collapse collapse" data-bs-parent="#tool-pane">
					<div class="accordion-body">
						<div class="d-flex flex-column">
							<div class="input-group mb-3 col-3">
								<button class="btn btn-primary"                @click="localStorage_saveSystem">Sauver une copie d'urgence</button>
								<button class="btn btn-primary bi bi-cassette" @click="localStorage_saveSystem"></button>
							</div>
							<div v-if="localStorage_hasSystem" class="input-group mb-3 col-3">
								<button class="btn btn-warning"             @click="localStorage_loadSystem">Charger la copie d'urgence</button>
								<button class="btn btn-danger bi bi-trash"  @click="localStorage_delSystem"></button>
							</div>
						</div>
					</div>
				</div>
			</div>
			<div class="accordion-item">
				<h2 class="accordion-header">
					<button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseThree" aria-expanded="false" aria-controls="collapseThree">
						Export / Import
					</button>
				</h2>
				<div id="collapseThree" class="accordion-collapse collapse" data-bs-parent="#tool-pane">
					<div class="accordion-body">
						<button class="btn btn-outline-primary" @click="downloadSystemByLink">Exporter système de grilles</button>
						<a class="hiddenFileImpExp" ref="downloadSystemLink">Download link</a>
						<div class="form-text">
							Vous trouverez les fichiers exportés dans les "Téléchargements" de votre navigateur,
							nommés par ex. {{ downloadSystemByLink_filename() }}.
						</div>

						<button class="btn btn-outline-primary" @click="$refs.uploadSystemInput.click()">Importer</button>
						<input class="hiddenFileImpExp" type="file" @change="uploadSystem" ref="uploadSystemInput" accept=".grille">

						<br><a href="./tarifs_ACA_202509.grille" download="tarifs_ACA_202509.grille">Exemple de fichier à importer</a>
					</div>
				</div>
			</div>
		</div>

		<div id="pricinggrid-pane" class="pt-2">
			<pricinggrids-tabs :ui_state="ui_state"></pricinggrids-tabs>

			<div id="gridViewport" class="mb-3">
				<pricinggrids-grid :ui_state="ui_state"></pricinggrids-grid>
			</div>

			<h3 id="dimension-list"><a href="#dimension-list">Légende</a></h3>
			<pricinggrids-dim-list :ui_state="ui_state"></pricinggrids-dim-list>
		</div>

	</div><!-- app end -->



	<!-- =========================================================== -->
	<!-- =============== Vue components ============================ -->

	<!-- ========== (some) component templates ============== -->


	<script type="text/x-template" id="PricingGrids_Tabs-template">
		<ul class="nav nav-tabs">
		<TransitionGroup name="list">
			<li v-for="grid in ui_state.system.grids" class="nav-item position-relative" :key="grid.$$key">
				<a href="#" class="nav-link" :class="{active: isSelected(grid.name)}" @click.prevent="selectGrid(grid.name)">
					{{grid.name}}
				</a>
				<a href="#" v-if="isSelected(grid.name)"
				  class="position-absolute top-0 end-0 bi bi-pen"
				  @click.prevent="editSelectedGrid_start"></a>
			</li>
			<li class="nav-item" key="+">
				<a href="#" class="nav-link bi bi-plus-lg" @click.prevent="editSelectedGrid_new"></a>
			</li>
		</TransitionGroup>
		</ul>

		<!-- Modal dialog template for Grid System customizer -->
		<div class="modal"  id="grid-system-customizer" tabindex="-1">
			<div class="modal-dialog modal-dialog-scrollable modal-fullscreen-sm-down">
				<form class="modal-content needs-validation">
					<div class="modal-header">
						<h5 class="modal-title">
							<template v-if="old_gridName">
								Modifier grille {{ old_gridName }}
							</template>
							<template v-else>
								Créer une nouvelle grille
							</template>
						</h5>
						<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
					</div>
					<div class="modal-body">
						<div class="input-group has-validation">
							<div class="col-4">
								<label class="col-form-label" for="inputName">Nom</label>
							</div>
							<div class="col-8">
								<input class="form-control" id="inputName" placeholder="Nom de la grille"
								   v-model.trim="new_gridName" required>
								<div class="invalid-feedback">
									Nom de la grille, doit être unique.
								</div>
							</div>
						</div>

					</div>
					<div class="modal-footer">
						<template v-if="old_gridName">
							<button type="button" class="btn btn-outline-secondary bi bi-caret-left-fill" @click="moveGrid(gridIdx,-1)" :disabled="!isMovable(gridIdx,-1)"></button>
							<button type="button" class="btn btn-outline-secondary bi bi-caret-right-fill" @click="moveGrid(gridIdx,+1)" :disabled="!isMovable(gridIdx,+1)"></button>
							<button type="button" class="btn btn-danger" @click="editSelectedGrid_delete" data-bs-dismiss="modal">Supprimer</button>
						</template>
						<button type="button" class="btn btn-secondary" @click="editSelectedGrid_clear" data-bs-dismiss="modal">Abandonner</button>
						<button type="submit" class="btn btn-primary" @click.prevent="editSelectedGrid_end">Valider</button>
					</div>
				</form>
			</div>
		</div>
	</script>


	<script type="text/x-template" id="PricingGrids_Grid-template">
		<table class="table table-bordered table-hover table-sm gridTable">
			<template v-if="dimensionCount==0">
				<thead class="table-dark">
					<tr>
						<th>Toutes livraisons</th>
					</tr>
				</thead>
				<tbody>
					<tr>
						<td>
							<pricinggrids-gridcell
								@edit-grid-cell="(cell)=>editGridCell_start(cell)"
								:cell="grid.ensureCellAt({})">
							</pricinggrids-gridcell>
						</td>
					</tr>
				</tbody>
			</template>
			<template v-else-if="dimensionCount==1">
				{{void(
					dim0 = grid.dimensions[0]
				)}}
				<thead class="table-dark">
					<tr>
						<th>{{ dim0.name }}</th>
						<th>Prix</th>
					</tr>
				</thead>
				<tbody>
					<tr v-for="(categ_dim0, categIdx_dim0) in dim0.categories">
						<th class="gridHead">{{ categoryLabel(dim0, categ_dim0, categIdx_dim0) }}</th>
						<td>
							<pricinggrids-gridcell
								@edit-grid-cell="(cell)=>editGridCell_start(cell)"
								:cell="grid.ensureCellAt({[dim0.name]: categ_dim0.value})">
							</pricinggrids-gridcell>
						</td>
					</tr>
				</tbody>
			</template>
			<template v-else-if="dimensionCount==2">
				{{void(
					dim0 = grid.dimensions[0],
					dim1 = grid.dimensions[1]
				)}}
				<thead>
					<tr class="table-dark">
						<th rowspan="2">{{ dim0.name }}</th>
						<th :colspan="dim1.categories.length">
							{{ dim1.name }}
						</th>
					</tr>
					<tr>
						<th v-for="(categ_dim1, categIdx_dim1) in dim1.categories" class="gridHead">
							{{ categoryLabel(dim1, categ_dim1, categIdx_dim1) }}
						</th>
					</tr>
				</thead>
				<tbody>
					<tr v-for="(categ_dim0, categIdx_dim0) in dim0.categories" >
						<th class="gridHead">
							{{ categoryLabel(dim0, categ_dim0, categIdx_dim0) }}
						</th>
						<td v-for="categ_dim1 in dim1.categories">
							<pricinggrids-gridcell
								@edit-grid-cell="(cell)=>editGridCell_start(cell)"
								:cell="grid.ensureCellAt({[dim0.name]: categ_dim0.value,[dim1.name]: categ_dim1.value})">
							</pricinggrids-gridcell>
						</td>
					</tr>
				</tbody>
			</template>
			<template v-else-if="dimensionCount==3">
				{{void(
					dim0 = grid.dimensions[0],
					dim1 = grid.dimensions[1],
					dim2 = grid.dimensions[2]
				)}}
				<thead>
					<tr class="table-dark">
						<th rowspan="4">{{ dim0.name }}</th>
						<th :colspan="dim2.categories.length * dim1.categories.length">
							{{ dim2.name }}
						</th>
					</tr>
					<tr>
						<th v-for="(categ_dim2, categIdx_dim2) in dim2.categories" :colspan="dim1.categories.length" class="gridHead">
							{{ categoryLabel(dim2, categ_dim2, categIdx_dim2) }}
						</th>
					</tr>
					<tr class="table-dark">
						<th v-for="categ_dim2 in dim2.categories" :colspan="dim1.categories.length">
							{{ dim1.name }}
						</th>
					</tr>
					<tr>
						<template v-for="categ_dim2 in dim2.categories">
						<th v-for="(categ_dim1, categIdx_dim1) in dim1.categories" class="gridHead">
							{{ categoryLabel(dim1, categ_dim1, categIdx_dim1) }}
						</th>
						</template>
					</tr>
				</thead>
				<tbody>
					<tr v-for="(categ_dim0, categIdx_dim0) in dim0.categories" >
						<th class="gridHead">{{ categoryLabel(dim0, categ_dim0, categIdx_dim0) }}</th>
						<template v-for="categ_dim2 in dim2.categories">
						<td v-for="categ_dim1 in dim1.categories">
							<pricinggrids-gridcell
								@edit-grid-cell="(cell)=>editGridCell_start(cell)"
								:cell="grid.ensureCellAt({[dim0.name]: categ_dim0.value,[dim1.name]: categ_dim1.value, [dim2.name]: categ_dim2.value})">
							</pricinggrids-gridcell>
						</td>
						</template>
					</tr>
				</tbody>
			</template>
			<template v-else>
				<tbody><tr><td>
					Dimensions &gt; 3 non support&eacute; !
				</td></tr></tbody>
			</template>
		</table>

		<!-- Modal dialog template for Cell customizer -->
		<div class="modal"  id="grid-cell-customizer" tabindex="-1">
			<div class="modal-dialog modal-dialog-scrollable modal-fullscreen-sm-down">
				<form class="modal-content needs-validation">
					<div class="modal-header">
						<h5 class="modal-title">Cellule de grille</h5>
						<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
					</div>
					<div class="modal-body" style="min-height: 50vh">
						<ul class="nav nav-pills">
							<li class="nav-item" v-for="[choice,choiceLabel] in [
								['FixedPrice','Prix fixe'],
								['PerVolumePrice', 'Prix /vol.'],
								['DelegatedPrice', 'Prix reporté']
							]">
								<a href="#" class="nav-link"
								  :class="{active: ui_state.editingPolicyChoice == choice}"
								  @click.prevent="ui_state.editingPolicyChoice = choice; editGridCell_clear()">
									{{choiceLabel}}
								</a>
							</li>
							<li class="nav-item dropdown">
								<a href="#" class="nav-link dropdown-toggle" data-bs-toggle="dropdown" role="button"
								  :class="{active: ui_state.editingPolicyChoice == 'clipboardPolicy'}"
								  @click.prevent="ui_state.editingPolicyChoice = 'clipboardPolicy'">
									<i class="bi bi-clipboard" aria-label="Clipboard"></i>
								</a>
								<ul class="dropdown-menu">
									<li><a href="#" class="dropdown-item" @click.prevent="editGridCell_pasteAndSave">Coller & Valider</a></li>
									<li><a href="#" class="dropdown-item" @click.prevent="editGridCell_paste">Coller</a></li>
									<li><hr class="dropdown-divider"></li>
									<li><a href="#" class="dropdown-item" @click.prevent="editGridCell_copy">Copier</a></li>
									<li><a href="#" class="dropdown-item" @click.prevent="editGridCell_emptyClipboard">Vider</a></li>
								</ul>
							</li>
							<li class="nav-item">
								<a href="#" class="nav-link" role="button" @click.prevent="editGridCell_copy">
									<i class="bi bi-copy" aria-label="Copy to Clipboard"></i>
								</a>
							</li>
						</ul>
						<div class="mt-3 px-2">
							{{ void(currCopy = ui_state.editingPolicyCopies[ui_state.editingPolicyChoice] )}}
							<template v-if="ui_state.editingPolicyChoice == 'clipboardPolicy'">
								<div v-if="currCopy" class="alert alert-info">
									<i class="bi bi-clipboard-check fs-2"></i>
									<pricinggrids-policy :policy="currCopy" editMode="no"/>
								</div>
								<div v-else class="alert alert-warning">
									<i class="bi bi-clipboard-x fs-2"></i>
									(Presse-papier vide)
								</div>
							</template>
							<template v-else>
								<pricinggrids-policy v-if="currCopy" :policy="currCopy" editMode="full" :ui_state="ui_state" />
								<div v-else class="text-bg-danger">
									UNKNOWN "editingPolicyChoice" : {{ ui_state.editingPolicyChoice }}
									<!-- meaning not listed in nav > nav-item -->
								</div>
							</template>
						</div>
					</div>
					<div class="modal-footer">
						<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Abandonner</button>
						<button type="submit" class="btn btn-primary" @click.prevent="editGridCell_end">Valider</button>
					</div>
				</form>
			</div>
		</div>
	</script>

	<script type="text/x-template" id="PricingGrids_Policy-template">
		<!-- TODO factorize "extra-info" across all policy types ? keep in all forms ?... -->
		<template v-if="policy.type == 'FixedPrice'">
			<template v-if="editMode=='full'">
				<div class="input-group has-validation">
					<span class="input-group-text">de</span>
					<money-input class="form-control" min="0" v-model="policy.price" required />
					<span class="input-group-text">€</span>
					<div class="invalid-feedback">
						Prix en euros
					</div>
				</div>
				<hr>
				<div class="input-group">
					<span class="input-group-text">Transporteur</span>
					<input type="text" class="form-control" v-model.trim="policy.extra_info">
				</div>
			</template>
			<template v-else-if="editMode=='quick'">
				<money-input v-model="policy.price" required/>
				<div class="quick-extra-info" v-if="policy.extra_info">
					{{ policy.extra_info }}
				</div>
			</template>
			<template v-else>
				Prix fixe de {{ policy.price }}€
				<div v-if="policy.extra_info">
					<hr>
					Transporteur: {{policy.extra_info}}
				</div>
			</template>
		</template>

		<template v-else-if="policy.type == 'PerVolumePrice'">
			<template v-if="editMode=='full'">
				<div class="input-group has-validation">
					<span class="input-group-text">Prix au</span>
					<select class="form-select" v-model="policy.attribute" required>
						<option disabled value="">Coordonnée brute</option>
						<option v-for="k in numericRawCoords" :value="k">
							{{ k }}
						</option>
					</select>
					<div class="invalid-feedback">
						Sélectionnez un attribute de volume.
					</div>
					<span class="input-group-text">arrondi au</span>
					<input class="form-control" type="number" step="0.25" min="0.25" v-model.number="policy.rounding" required>
					<span class="input-group-text">supérieur</span>
					<div class="invalid-feedback">
						Taille du "paquet" auquel appliquer le prix unitaire (ex. 0.5, 1, 10, 50, 100)
					</div>
				</div>
				<div class="input-group has-validation mt-3">
					<span class="input-group-text">de</span>
					<money-input class="form-control" min="0" v-model="policy.price" required />
					<span class="input-group-text">€</span>
					<span class="input-group-text">par unité</span>
					<div class="invalid-feedback">
						Prix en euros pour 1 unité (indépendant de l'arrondi)
					</div>
				</div>
				<div class="input-group mt-3">
					<div class="input-group-text">(Optionnel)</div>
					<button type="button" class="btn btn-outline-secondary bi bi-arrow-bar-up" @click="toggleOffset">
						Prix d'excédent
					</button>
				</div>
				<div class="input-group has-validation" v-if="policy.offset">
					<span class="input-group-text">Au delà de :</span>
					<input class="form-control" type="number" step="any" min="0" v-model.number="policy.offset.attribute" required>
					<span class="input-group-text">unités</span>
					<span class="input-group-text">pour</span>
					<money-input class="form-control" min="0" v-model="policy.offset.price" required/>
					<span class="input-group-text">€</span>
					<div class="invalid-feedback">
						Prix et unités de départ doivent être positifs.
					</div>
				</div>
				<div v-if="policy.offset" class="form-text">
					Attention à bien positionner le nombre d'unités à la valeur de départ de la catégorie correspondante, pour rester cohérent. Ex.: mettre "30" pour une catégorie de poids "30+ kg".
				</div>
				<hr>
				<div class="input-group">
					<span class="input-group-text">Transporteur</span>
					<input type="text" class="form-control" v-model.trim="policy.extra_info">
				</div>
			</template>
			<template v-else-if="editMode=='quick'">
				<money-input v-model="policy.price" required />*{{policy.attribute}}
				<div class="secondary" v-if="policy.offset">
					à partir de {{ policy.offset.attribute }} pour {{ policy.offset.price }}€
				</div>
				<div class="secondary">
					(arrondi à {{ policy.rounding }})
				</div>
				<div class="quick-extra-info" v-if="policy.extra_info">
					{{ policy.extra_info }}
				</div>
			</template>
			<template v-else>
				Prix au "{{ policy.attribute }}"<br>
				(arrondi au {{ policy.rounding }} supérieur)<br>
				de {{ policy.price }}€ par unité
				<template v-if="policy.offset">
					(à partir de {{ policy.offset.attribute }} pour {{ policy.offset.price }}€)
				</template>
				<div v-if="policy.extra_info">
					<hr>
					Transporteur: {{policy.extra_info}}
				</div>
			</template>
		</template>

		<template v-else-if="policy.type == 'DelegatedPrice'">
			<template v-if="editMode=='full'">
				<div class="input-group has-validation">
					<span class="input-group-text">Se reporter à la grille</span>
					<select class="form-select" v-model="policy.delegated_gridName" required>
						<option disabled value="">Choisissez une grille</option>
						<option v-for="k in ui_state.system.grids.map(g=>g.name).filter(n=>n!=ui_state.currentGrid.name)" :value="k">
							{{ k }}
						</option>
					</select>
					<div class="invalid-feedback">
						Sélectionnez la grille à suivre.
					</div>
				</div>
				<div class="input-group has-validation mt-3">
					<span class="input-group-text">Frais supplémentaire : </span>
					<money-input class="form-control" v-model="policy.delegated_additiveAmount" />
					<span class="input-group-text">€</span>
					<i class="input-group-text">(optionnel)</i>
					<div class="invalid-feedback">
						Frais à ajouter en €, après avoir appliqué la griller à suivre.
					</div>
				</div>
				<hr>
				<div class="input-group">
					<span class="input-group-text">Transporteur</span>
					<input type="text" class="form-control" v-model.trim="policy.extra_info">
				</div>
			</template>
			<template v-else-if="editMode=='quick'">
				voir grille "{{ policy.delegated_gridName }}"<br>
				{{ policy.delegated_additiveAmount ? "+ ajout "+policy.delegated_additiveAmount+"€" : ""}}
				<!-- quick mode is no edit for now... may change -->
				<div class="quick-extra-info" v-if="policy.extra_info">
					{{ policy.extra_info }}
				</div>
			</template>
			<template v-else>
				voir grille "{{ policy.delegated_gridName }}"<br>
				{{ policy.delegated_additiveAmount ? "+ ajout "+policy.delegated_additiveAmount+"€" : ""}}
				<!-- TODO ajout mention "type de frais" ? genre "Livraison directe" -->
				<!-- TODO ou mieux : ajout d'une composition additive/multiplicative générale -->
				<div v-if="policy.extra_info">
					<hr>
					Transporteur: {{policy.extra_info}}
				</div>
			</template>
		</template>
		<template v-else><!-- UNKNOWN POLICY TYPE -->
			<template v-if="editMode=='full'">
				<div class="alert alert-danger d-flex align-items-center" role="alert">
					<i class="bi bi-exclamation-triangle-fill fs-1"></i>
					<div>
						ERREUR - Type de prix inconnu : {{ policy.type }}
					</div>
				</div>
			</template>
			<template v-else-if="editMode=='quick'">
				<span class="badge text-bg-danger">UNKNOWN</span>
					{{ policy.type }}
			</template>
			<template v-else>
				{{ policy }}
			</template>
		</template>
	</script>

	<script type="text/x-template" id="PricingTest-Form-template">
		<form>
			<div class="d-flex column-gap-3">
				<div><input type="radio" v-model="ui_state.testPricedObj.market" value="BTB"> BTB</div>
				<div><input type="radio" v-model="ui_state.testPricedObj.market" value="BTC"> BTC</div>
				<div><input type="checkbox" v-model="ui_state.testPricedObj.isIntegration" value="true"> Integration</div>
			</div>
			<div class="row mb-3 mb-lg-1">
				<div class="col-lg-4">
					<label class="col-form-label" for="inputPoids">Poids</label>
				</div>
				<div class="col-lg-8">
					<input class="form-control" id="inputPoids" placeholder="Poids (en kg)"
					  type="number" step="0.1" min="0"
					  v-model.number="ui_state.testPricedObj.poids">
				</div>
			</div>
			<div class="row mb-3 mb-lg-1">
				<div class="col-lg-4">
					<label class="col-form-label" for="inputPostCode">Code postal</label>
				</div>
				<div class="col-lg-8">
					<input class="form-control" id="inputPostCode" placeholder="Code postal"
					  type="text" maxlength="5"
					  v-model.trim="ui_state.testPricedObj.codePostal">
				</div>
			</div>
			<div class="row mb-3 mb-lg-1">
				<div class="col-lg-4">
					<label class="col-form-label" for="inputCountry">Pays</label>
				</div>
				<div class="col-lg-8">
					<input class="form-control" id="inputCountry"
					  type="text" list="countryDatalist" autocomplete="on"
					  v-model="ui_state.testPricedObj.pays">
					<datalist id="countryDatalist">
						<option value="Allemagne"></option>
						<option value="Autriche"></option>
						<option value="Belgique"></option>
						<option value="Bulgarie"></option>
						<option value="Croatie"></option>
						<option value="Danemark"></option>
						<option value="Espagne (hors îles)"></option>
						<option value="Estonie"></option>
						<option value="Finlande"></option>
						<option value="France"></option>
						<option value="Grèce (hors îles)"></option>
						<option value="Hongrie"></option>
						<option value="Irlande"></option>
						<option value="Islande"></option>
						<option value="Italie"></option>
						<option value="Lettonie"></option>
						<option value="Luxembourg"></option>
						<option value="Norvège"></option>
						<option value="Pays-Bas"></option>
						<option value="Pologne"></option>
						<option value="Portugal"></option>
						<option value="Rép. Tchèque"></option>
						<option value="Roumanie"></option>
						<option value="Suisse"></option>
						<option value="Suède"></option>
						<option value="Slovaquie"></option>
					</datalist>
				</div>
			</div>
			<div class="row mb-3 mb-lg-1">
				<div class="input-group">
					<span class="input-group-text">L</span>
					<input type="text" class="form-control" v-model.number="ui_state.testPricedObj.size_length" placeholder="(cm)"/>
					<span class="input-group-text">l</span>
					<input type="text" class="form-control" v-model.number="ui_state.testPricedObj.size_width" placeholder="(cm)"/>
					<span class="input-group-text">h</span>
					<input type="text" class="form-control" v-model.number="ui_state.testPricedObj.size_height" placeholder="(cm)"/>
				</div>
			</div>
			<div class="row mb-3 mb-lg-1">
				<div class="input-group">
					<span class="input-group-text">Colis</span>
					<input type="number" class="form-control" step="1" min="0" v-model="ui_state.testPricedObj.size_parcel_count"/>
				</div>
			</div>
			<div class="row mb-3 mb-lg-1">
				<div class="col-lg-4">
					<label class="col-form-label" for="inputtransporteur100">Transporteur 100+</label>
				</div>
				<div class="col-lg-8">
					<input class="form-control" id="inputtransporteur100"
					  type="text" list="transporteur100Datalist" autocomplete="on"
					  v-model="ui_state.testPricedObj.transporteur100">
					<datalist id="transporteur100Datalist">
						<option value="Schenker Standard (MES)"></option>
						<option value="Schenker Premium (MES)"></option>
						<option value="MAZET"></option>
						<option value="Geodis MES"></option>
						<option value="Geodis ATX"></option>
					</datalist>
				</div>
			</div>

			<!-- PRICING TEST RESULT -->
			<table class="table" style="font-size:0.8em">
				<thead>
					<tr>
						<th scope="col">Grille @ Case</th>
						<th scope="col">Tarif</th>
						<th scope="col">Cumul</th>
					</tr>
				</thead>
				<tbody>
					<pricingtest-result :result="testResult"/>
				</tbody>
				<tfoot class="table-group-divider">
					<tr>
						<td colspan="3" class="fs-3">
							Total:
							<template v-if="!isNaN(testResult?.amount)">
								{{testResult.amount.toFixed(2)}} €
							</template>
							<span v-else class="text-bg-danger">
								&nbsp;???&nbsp;
							</span>
							<div class="fs-4" v-if="testResult.extra_info">
								{{ testResult.extra_info }}
							</div>
						</td>
					</tr>
				</tfoot>
			</table>


		</form>
	</script>



	<script type="text/x-template" id="PricingTest-Result-template">
		<pricingtest-result v-if="result.nested" :result="result.nested" />
		<tr>
			<td>
				{{ result.gridName}}<br>
				<span v-if="result.gridCell?.coords" style="white-space:pre;">
					{{ pretty_coords(result.gridCell.coords) }}
				</span>
			</td>
			<td>
				<template v-if="result.gridCell?.policy">
					<pricinggrids-policy :policy="result.gridCell.policy" editMode="no"/>
				</template>
				<template v-else>
					N/A
				</template>
			</td>
			<td>
				<template v-if="!isNaN(result.amount)">
					{{result.amount.toFixed(2)}}
				</template>
				<span v-else class="text-bg-danger">
					&nbsp;???&nbsp;
				</span>
			</td>
		</tr>
	</script>


	<!-- ========== component logic ============== -->
	<script type="module">

		let typicalRawCoords = Object.entries(new CommandeALivrer(0, "01000").getPPGRawCoordinates()); //arguably typical ?...

		const numericRawCoords =  typicalRawCoords.filter(([k,v]) => typeof v == "number").map(([k,v]) => k);
		const stringRawCoords =  typicalRawCoords.filter(([k,v]) =>typeof v == "string").map(([k,v]) => k);
		const DEFAULT_POLICIES = {
			"FixedPrice": {
				type: "FixedPrice",
				price: null
			},
			"PerVolumePrice": {
				type: "PerVolumePrice",
				attribute: null,
				rounding: 10,
				price: null,
				/* offset : {
					attribute:0,
					price:0
				} */
			},
			"DelegatedPrice": {
				type: "DelegatedPrice",
				delegated_gridName: "",
				delegated_additiveAmount: null
			},
		};

		const DEFAULT_PRICINGSYSTEM = new PricingSystem("Compagnie_1");
		DEFAULT_PRICINGSYSTEM.grids.push(new PricingGrid("Grille_1"));


		/* shared state for the page */
		//const gridBuilderApp_UI = Vue.reactive( ui_state); TODO need explicit call ?!

		const gridBuilderApp = Vue.createApp({
			data() {
				return {
					pgv_metadata:null,
					ui_state: { // TODO utiliser un bus global ?...
						system: DEFAULT_PRICINGSYSTEM,
						currentGrid: DEFAULT_PRICINGSYSTEM.grids[0],

						editingPolicyCell: null,
						editingPolicyChoice: "clipboardPolicy", //or a real policy type
						editingPolicyCopies:{
							"clipboardPolicy" : null,
							... DEFAULT_POLICIES
						},


						//end TODO XXXXXXXXXXXXXXXXXXX

						editingDimName: "",
						editingDimCopy: null,

						testPricedObj: new CommandeALivrer(1 /*kg*/, "77600"),

						confirmCancelDim: function(callback){
							let continueFunc = ()=>{
								this.editingDimName = "";
								this.editingDimCopy = null;
								callback();
							};

							if (this.editingDimCopy) {
								confirm_dialog("Dimension","Modification en cours, abandonner ?",{
									label:'Continuer', class: 'btn-primary', autofocus:true,
									handler: continueFunc
								}, {
									label:'Annuler', class: 'btn-secondary',
								});
							} else {
								continueFunc();
							}

						}
					},
					localStorage_hasSystem : false, // since cannot make localStorage reactive ;-)
					needSaving: false, // "dirty" mark on PriceGrids
				}
			},
			watch:{
				"ui_state.system": {
		            handler: function(){
						this.needSaving = true;
                    },
            		deep: true,
            		immediate: false
				},
				needSaving(v){
					if (v) {console.log("sauvez-moi");}
else  {console.log("sans façon");}
					
				} 

        	},
			mounted(){
				this.apiGetMetadata();
				this.apiGetJsonContent();

				let saved = localStorage.getItem("save.system");
				this.localStorage_hasSystem = !(saved == null || typeof saved == "undefined" || saved == "");

				window.addEventListener('beforeunload',()=>{
					console.info(`Emergency autosave of current PriceGrid to localStorage`);
					this.localStorage_saveSystem(false);
				});
			},
			methods: {
				loadSystemFromString(data){
					if (data) {
						this.ui_state.system = PricingSystem.fromJSON(data);
						this.ui_state.currentGrid = this.ui_state.system.grids[0];
					} else {
						throw new Error("Could not load from empty data");
					}
					this.$nextTick(() => {						
						this.needSaving = false;
					});
				},
				apiGetMetadata(){
					let metadataUri =`price-grids/\${PRICE_GRID_ID}/versions/\${PRICE_GRID_VERSION_ID}`;

					axios_backend.get(metadataUri)
					.then(response => {
						this.pgv_metadata = response.data;
						this.$nextTick(() => {
							let gridDesc = this.pgv_metadata.priceGrid.description;
							let versionDesc = this.pgv_metadata.description;

							if (gridDesc) new bootstrap.Tooltip(this.$refs.gridLabel, {title:gridDesc, customClass:"tooltip-pre"});
							if (versionDesc) new bootstrap.Tooltip(this.$refs.versionLabel, {title:versionDesc, customClass:"tooltip-pre"});
						});
					})
					.catch(error => {
						showAxiosErrorDialog(error);
					})
				},
				apiGetJsonContent(){
					let dataUri =`price-grids/\${PRICE_GRID_ID}/versions/\${PRICE_GRID_VERSION_ID}/jsonContent`;

					axios_backend.get(dataUri)
					.then(response => {
						this.loadSystemFromString(response.data);
					})
					.catch(error => {
						showAxiosErrorDialog(error);
					})
				},
				apiPutJsonContent(){
					let _v_lock = this.pgv_metadata._v_lock;
					let dataUri =`price-grids/\${PRICE_GRID_ID}/versions/\${PRICE_GRID_VERSION_ID}/jsonContent?_v_lock=\${_v_lock}`;

					axios_backend.put(dataUri, this.ui_state.system)
					.then(response => {
						this.apiGetMetadata();
						this.needSaving = false;
					})
					.catch(error => {
						showAxiosErrorDialog(error);
					})
				},
				localStorage_saveSystem(useAlert = true){
					let handler = ()=>{
						let data = JSON.stringify(this.ui_state.system);
						localStorage.setItem("save.system", data);
						this.localStorage_hasSystem = true;
					};

					if (useAlert && this.localStorage_hasSystem) {
						confirm_dialog("Stockage local","Écraser sauvegarde d'urgence ?",{
							label:'Continuer', class: 'btn-primary', autofocus:true,
							handler
						}, {
							label:'Abandonner', class: 'btn-secondary',
						});
					} else {
						handler();
					}
				},
				localStorage_loadSystem(name, useAlert = true){
					let handler = ()=>{
						let data = localStorage.getItem("save.system");
						this.loadSystemFromString(data);
					};

					if (useAlert) {
						confirm_dialog("Stockage local","Attention, en ouvrant cette sauvegarde d'urgence, vous allez remplacer toutes les grilles courantes par la sauvegarde.",{
							label:'Continuer', class: 'btn-primary', autofocus:true,
							handler
						}, {
							label:'Abandonner', class: 'btn-secondary',
						});
					} else {
						handler();
					}
				},
				localStorage_delSystem(){ // option for localStorage.clear(); ?
					confirm_dialog("Stockage local","Supprimer la sauvegarde d'urgence ?",{
						label:'Continuer', class: 'btn-primary', autofocus:true,
						handler : ()=>{
							localStorage.removeItem("save.system");
							this.localStorage_hasSystem = false;
						}
					}, {
						label:'Abandonner', class: 'btn-secondary',
					});
				},

				downloadSystemByLink(){
					console.info("Generating a lengthy download link from PricingSystem...");
					let data = JSON.stringify(this.ui_state.system);
					const linkData = new Blob([data], { type: 'application/json' });
					const linkHref =  URL.createObjectURL(linkData);

					let el = this.$refs.downloadSystemLink;
					el.href = linkHref;
					el.download = this.downloadSystemByLink_filename();
					el.click();
				},
				downloadSystemByLink_filename(){
					if (!this.pgv_metadata) return null;
					let dateTag = ((dtUTC) => { /* expected data format by JaxRS : "2025-10-30T10:24:43Z[UTC]" */
						if (dtUTC == null || dtUTC == "") return "";
						if (/^(\d{4})-(\d{2})-(\d{2})T(\d{2})\:(\d{2})\:(\d{2})(\.\d+)?Z\[UTC\]$/.test(dtUTC)) {
							dtUTC = dtUTC.slice(0, -("[UTC]".length)); //changed to a JS supported "simplified ISO8061"
							let date = new Date(Date.parse(dtUTC));
							return date.toISOString().replaceAll(/[^\d]/g, "").slice(0,12);
						} else {
							return "";
						}
					})(this.pgv_metadata?.auditingInfo?.dateModified);

					return this.pgv_metadata.priceGrid.name
						+ "__" + this.pgv_metadata.version
						+(dateTag ? "["+ dateTag+"]" : "")
						+".grille";
				},
				uploadSystem(event){
					let inputFld = event.target;
					let file = (inputFld?.files && inputFld.files.length > 0) ?  inputFld.files[0] : null;
					if (!file) return; // silently
					const fileReader = new FileReader();
					fileReader.onload = ()=>{
						try {
							this.loadSystemFromString(fileReader.result);
						} catch(err){
							alert_dialog("Import de Grille", "Erreur d'import: "+ err);
						}
					};
					fileReader.onerror = (event)=>{
						alert_dialog("Import de Grille", "Erreur de lecture du fichier: " + event.target.error);
					};
					fileReader.readAsText(file);
				}

			},
		});


		var PricingGrids_Tabs = {
			props: {
				ui_state: Object
			},
			data(){
				return {
					old_gridName: "",
					new_gridName : ""
				}
			},
			computed:{
				gridIdx(){// reconstructed here with currentGrid, to mimic moveDimension() style methods
					return this.ui_state.system.grids.findIndex(g => g === this.ui_state.currentGrid);
				}
			},
			methods: {
				_showModal(b){
					const modal = document.getElementById("grid-system-customizer");
					const bsModal = bootstrap.Modal.getOrCreateInstance(modal);
					if (b) bsModal.show(); else bsModal.hide();
				},

				selectGrid(name){
					this.ui_state.confirmCancelDim(
						()=>{ this.ui_state.currentGrid = this.ui_state.system.findGridByName(name); }
					);
				},
				isSelected(name){
					return this.ui_state.currentGrid.name == name;
				},

				moveGrid(fromIdx, offset){
					let grids = this.ui_state.system.grids;
					let toIdx = fromIdx + offset;
					if (fromIdx < 0 || fromIdx >= grids.length) throw new Error("'From' index out of range");
					if (toIdx < 0 || toIdx >= grids.length) throw new Error("'To' index out of range");
					[grids[fromIdx], grids[toIdx]] = [grids[toIdx], grids[fromIdx]];
				},
				isMovable(fromIdx, offset){
					let grids = this.ui_state.system.grids;
					let toIdx = fromIdx + offset;
					return (toIdx >= 0 && toIdx < grids.length);
				},

				editSelectedGrid_new(){
					this.old_gridName = null; // <- marks the new
					this.new_gridName = "";
					this._showModal(true);
				},
				editSelectedGrid_start(){
					this.old_gridName = this.ui_state.currentGrid.name;
					this.new_gridName = this.old_gridName;
					this._showModal(true);
				},
				editSelectedGrid_end(){
					let form = event.target.closest("form.needs-validation");

					// 1) Validate form
					// 1.a) name unicity check
					let name_field = form.querySelector("#inputName");

					if (this.new_gridName != this.old_gridName
					  && this.ui_state.system.findGridByName(this.new_gridName)){
						name_field.setCustomValidity("Noms en doublon");
					} else {
						name_field.setCustomValidity("");
					}

					// 1.b) validate other attribs
					if (!form.checkValidity()) {
						event.preventDefault();
						event.stopPropagation();
						form.classList.add('was-validated')
						return;
					}

					// 2) Save form
					if (this.old_gridName) {
						this.ui_state.system.renameGrid(this.old_gridName, this.new_gridName);
					} else {
						this.ui_state.system.addNewGrid(this.new_gridName);
						this.selectGrid(this.new_gridName);
					}
					this._showModal(false);
				},
				editSelectedGrid_delete(){
					if (this.ui_state.system.grids.length <= 1) {
						alert_dialog("Suppression de Grille", "Il faut conserver au moins une grille !");
						return; //abort
					}

					const gridName = this.ui_state.currentGrid.name;
					confirm_dialog("Suppression de Grille",`Vraiment ? Effacer la grille "${gridName}" vous fera perdre toutes les données qu'elle contient !`,{
						label:'Continuer', class: 'btn-danger', /* autofocus:true,  no reason to make it easy ;-) */
						handler : ()=>{
							try {
								let grid = this.ui_state.system.removeGrid(gridName);
								if (grid){
									console.info(`Deleted Grille "${gridName}".`);
									this.ui_state.currentGrid = this.ui_state.system.grids[0];//fallback to 1st available
								} else {
									console.error(`Unexpected problem while deleting Grille "${gridName}".`);
								}

							} catch(err){
								//console.info(err); // better check for new unexpected causes...
								alert_dialog("Suppression de Grille", `Suppression impossible, car cette grille est probablement référencée par d'autres. (${err})`);
								return false; // veto permet la visu, ici, du la "dialog dans la dialog"
							}
						}
					}, {
						label:'Abandonner', class: 'btn-secondary',
					});
				},
				editSelectedGrid_clear(){
					const modal = document.getElementById("grid-system-customizer");
					const form = modal.querySelector("form.needs-validation");
					form.classList.remove('was-validated');
				}
			},
			mounted(){
				const modal = document.getElementById("grid-system-customizer");
				modal.addEventListener('hidden.bs.modal', (event) => {
					this.editSelectedGrid_clear();
				});
			},
			template: '#PricingGrids_Tabs-template'
		};


		var _AbstractDimension = {
			props: {
				dimension: Object,
				ui_state: Object
			},
			data(){
				return {
					numericRawCoords,
					stringRawCoords
				}
			},
			computed: {
				isEditing(){
					return (this.dimension.name == this.ui_state.editingDimName);
				}
			}
		};


		var PricingGrids_DimensionList = {
			props: {
				ui_state: Object
			},
			data(){
				return {
					newDimType:"ThresholdCategory" // default, because more common
				}
			},
			methods: {
				newDimension(){
					this.ui_state.confirmCancelDim(()=>{
						let newDim = this.ui_state.currentGrid.addNewDimension(this.newDimType);
						this.editDimension_start(null, newDim.name);
					});
				},
				removeDimension(idx){
					let removedDim = this.ui_state.currentGrid.dimensions[idx];
					confirm_dialog("Dimension",`Êtes-vous sûr de vouloir supprimer la dimension "${removedDim.name}" ?
									(Vous perdrez alors toutes les cellules correspondantes)`,{
						label:'Continuer', class: 'btn-primary', autofocus:true,
						handler : ()=>{
							this.ui_state.currentGrid.removeDimension(idx);
							this.ui_state.editingDimName = "";
							this.ui_state.editingDimCopy = null;
						}
					}, {
						label:'Abandonner', class: 'btn-secondary',
					});
				},
				moveDimension(fromIdx, offset){
					let dimensions = this.ui_state.currentGrid.dimensions;
					let toIdx = fromIdx + offset;
					if (fromIdx < 0 || fromIdx >= dimensions.length) throw new Error("'From' index out of range");
					if (toIdx < 0 || toIdx >= dimensions.length) throw new Error("'To' index out of range");
					[dimensions[fromIdx], dimensions[toIdx]] = [dimensions[toIdx], dimensions[fromIdx]];
				},
				isMovable(fromIdx, offset){
					let dimensions = this.ui_state.currentGrid.dimensions;
					let toIdx = fromIdx + offset;
					return (toIdx >= 0 && toIdx < dimensions.length);
				},
				editDimension_start(event, name){
					this.ui_state.confirmCancelDim(()=>{
						if (event) this._clearEditing(event);

						let editingDim = this.ui_state.currentGrid.findDimensionByName(name);
						if (!editingDim) throw new Error(`Dimension "${name}" cannot be found for editing.`);

						this.ui_state.editingDimCopy = deepClone(editingDim);
						this.ui_state.editingDimName = name;
					});
				},
				editDimension_end(event){
					let form = event.target.closest("form.needs-validation")

					// 1) Validate form
					// 1.a) name unicity check
					let name_field = form.querySelector("#dim-name");
					let oldName = this.ui_state.editingDimName;
					let newName = this.ui_state.editingDimCopy.name;

					if (newName != oldName
					  &&  this.ui_state.currentGrid.findDimensionByName(newName)){
						name_field.setCustomValidity("Noms en doublon");
					} else {
						name_field.setCustomValidity("");
					}

					// 1.b) validate other attribs
					if (!form.checkValidity()) {
						event.preventDefault();
						event.stopPropagation();
						form.classList.add('was-validated')
						return;
					}

					// 2) Save form
					let editingDim = this.ui_state.currentGrid.findDimensionByName(oldName);
					if (!editingDim) throw new Error("Cannot save to dimension : " + oldName);

					// 2.a) adjust new name if needed
					if (oldName != newName) this.ui_state.currentGrid.renameDimension(oldName, newName);

					// 2.b) clean categories
					let categories = this.ui_state.editingDimCopy.categories;
					// - fuse categories with same value (for Enum-based)
					if (this.ui_state.editingDimCopy.type == "EnumCategory"){
						for (const c1 of categories){
							for (const c2 of categories){
								if (c1===c2) continue;
								if (c2.value == c1.value) {
									c1.enum = c1.enum.concat(c2.enum);
									c2.enum = [];
									c2.value = ""; // mark for pruning
								}
							}
						}
					}
					// - prune all categories with no value (= empty name)
					categories = categories.filter(c => !(typeof c.value == "string" && c.value==""));
					this.ui_state.editingDimCopy.categories = categories;

					// 2.c) ... *then* copy other attribs
					Object.assign(editingDim, this.ui_state.editingDimCopy);

					// 2.d) update cells for categories change
					this.ui_state.currentGrid.updateCellsFromDimensions();

					this._clearEditing(event);
				},

				editDimension_abort(event){
					this._clearEditing(event);
				},

				_clearEditing(event){
					let form = event.target.closest("form.needs-validation")
					form.classList.remove('was-validated');

					this.ui_state.editingDimName = "";
					this.ui_state.editingDimCopy = null;
				},


			},
			components :{
				ThresholdCategoryDimension:{
					extends: _AbstractDimension,
					computed:{
						categoryThresholdList: {
							get() {
								return this.ui_state.editingDimCopy.categories.map(c => c.value).join(" ; ");
							},
							set(value) {
								let asCleanStr = value.replaceAll(/[^\d.]+/g, ";");
								let asNumbers = asCleanStr.split(";").map(s => parseFloat(s, 10)).filter(n => n >=0);
								let asUniqueNumbers = [ ...new Set(asNumbers)];
								let categoryValues = asUniqueNumbers.sort((a, b) => a - b);

								let newCategories = categoryValues.map( v => ({value:v}) );
								this.ui_state.editingDimCopy.categories = newCategories;
							}
						}
					},
					template:
						`<div v-if="isEditing">
							<div class="input-group mb-3">
								<input id="dim-name" class="form-control" placeholder="Nom interne" v-model.trim="ui_state.editingDimCopy.name" required>
								<span class="input-group-text">par seuil de</span>
								<select class="form-select" v-model="ui_state.editingDimCopy.raw_name" required>
									<option disabled value="">Coordonnée brute</option>
									<option v-for="k in numericRawCoords" :value="k">
										{{ k }}
									</option>
								</select>
								<span class="invalid-feedback">
									Nom interne unique et non-vide (et court de préférence)
								</span>
							</div>
							<div class="row">
								<div class="col-3">
									<label class="form-label" for="dim-categoryThresholdList">Liste des seuils</label>
								</div>
								<div class="col-3">
									<select class="form-select mb-1" v-model="ui_state.editingDimCopy.comparison">
										<option value="eqSup">&gt;=</option>
										<option value="strictSup">&gt</option>
									</select>
								</div>
							</div>
							<input class="form-control" id="dim-categoryThresholdList" v-model.lazy="categoryThresholdList">
						</div>
						<div v-else>
							"{{ dimension.name }}" : par seuil de "{{ dimension.raw_name }}"
							({{ dimension.categories.map(c=>c.value).join(", ") }})
							 , {{ (dimension.comparison ?? "eqSup")=="eqSup" ? "égal ou supérieur" : "strictement supérieur" }}
						</div>`
				},
				EnumCategoryDimension:{
					extends: _AbstractDimension,
					computed: {
						categoryAlerts(){
							let categoryAlerts = [];
							const categories = this.ui_state.editingDimCopy.categories;

							// category values (="names")
							let categoryNames = categories.map(c => c.value);
							if (categoryNames.includes("")){
								categoryAlerts.push(`Attention, les catégories sans nom seront supprimées !`);
							}

							categoryNames = categoryNames.filter(v => v!="");
							{
								const dupes =  Array.from(new Set(categoryNames.filter((item, i) => categoryNames.indexOf(item) !== i)));
								if (dupes.length > 0){
									categoryAlerts.push(`Des catégories portent le même nom : ${dupes}. Les doublons seront fusionnés !`);
								}
							}

							const oldCategoryNames = this.dimension.categories.map(c => c.value);
							{
								const lostCategoryNames = oldCategoryNames.filter(n => !categoryNames.includes(n));
								if (lostCategoryNames.length > 0){
									categoryAlerts.push(`Les catégories suivantes ont disparu, les cellules correspondantes seront perdues : ${lostCategoryNames}.`);
								}
							}

							// intra-category dupes
							for (const cat of categories){
								const dupes =  Array.from(new Set(cat.enum.filter((item, i) => cat.enum.indexOf(item) !== i)));
								if (dupes.length > 0){
									categoryAlerts.push(`La catégorie "${cat.value}" contient les doublons suivants : ${dupes}.`);
								}
							}
							// cross-category dupes
							for (let x=0; x<categories.length; x++){
								for (let y=0; y<categories.length; y++){
									if (x >= y) continue;
									const catx = categories[x], caty = categories[y];
									const sx = new Set(catx.enum), sy = new Set(caty.enum);
									//const dupes = sx.intersection(sy); exists since... 2024. A bit too fresh for me
									const dupes = Array.from(new Set([...sx].filter(v => sy.has(v))));
									if (dupes.length > 0){
										categoryAlerts.push(`Les catégories "${catx.value}" et "${caty.value}" contiennent en commun : ${dupes}.`);
									}
								}
							}
							return categoryAlerts;
						}
					},
					methods:{
						addCategory(){
							this.ui_state.editingDimCopy.categories.push({value:"<Nouv.>", enum:[]}); //TODO defaulting
						}
					},
					template:
						`<div v-if="isEditing">
							<div class="input-group mb-3">
								<input id="dim-name" class="form-control" placeholder="Nom interne" v-model.trim="ui_state.editingDimCopy.name" required>
								<span class="input-group-text">sur liste de</span>
								<select class="form-select" v-model="ui_state.editingDimCopy.raw_name" required>
									<option disabled value="">Coordonnée brute</option>
									<option v-for="k in stringRawCoords" :value="k">
										{{ k }}
									</option>
								</select>
								<div class="invalid-feedback">
									Nom interne unique et non-vide (et court de préférence)
								</div>
							</div>

							<label class="form-label">Catégories</label>
							<div class="container">
								<div class="input-group" v-for="cat in ui_state.editingDimCopy.categories">
									<input class="form-control" v-model.trim="cat.value" style="flex-grow: 0; flex-basis:6em">
									<span class="input-group-text">:</span>
									<splitting-input class="form-control" v-model="cat.enum"></splitting-input>
								</div>
								<button type="button" @click="addCategory" class="btn btn-outline-secondary bi bi-plus-lg"></button>
								<div v-if="categoryAlerts.length>0" class="alert alert-warning fade show mt-1" role="alert">
									<i class="bi bi-exclamation-triangle fs-3"></i>
									Attention !
									<ul>
										<li v-for="ca in categoryAlerts">{{ ca }}</li>
									</ul>
								</div>
							</div>
						</div>
						<div v-else>
							"{{ dimension.name }}" : sur liste de "{{ dimension.raw_name }}"
							<ul>
								<li v-for="cat in dimension.categories">
									<strong>{{ cat.value }}</strong> : <em>{{ cat.enum.join(", ") }}</em>
								</li>
							</ul>
						</div>`
				},

				DirectCategoryDimension:{
					extends: _AbstractDimension,
					computed:{
						categoryList: {
							get() {
								return this.ui_state.editingDimCopy.categories.map(c => c.value).join(" ; ");
							},
							set(value) {
								let asTokens = value.split(";").map(v => v.trim());
								let asUniqueTokens = [ ...new Set(asTokens)];
								let categoryValues = asUniqueTokens.sort((a, b) => a - b);

								let newCategories = categoryValues.map( v => ({value:v}) );
								this.ui_state.editingDimCopy.categories = newCategories;
							}
						}
					},
					template:
						`<div v-if="isEditing">
							<div class="input-group mb-3">
								<input id="dim-name" class="form-control" placeholder="Nom interne" v-model.trim="ui_state.editingDimCopy.name" required>
								<span class="input-group-text">par valeur directe de </span>
								<select class="form-select" v-model="ui_state.editingDimCopy.raw_name" required>
									<option disabled value="">Coordonnée brute</option>
									<option v-for="k in stringRawCoords" :value="k">
										{{ k }}
									</option>
								</select>
								<span class="invalid-feedback">
									Nom interne unique et non-vide (et court de préférence)
								</span>
							</div>

							<label class="form-label" for="dim-categoryList">Liste des valeurs</label>
							<input class="form-control" id="dim-categoryList" v-model.lazy="categoryList">
						</div>
						<div v-else>
							"{{ dimension.name }}" : par valeur de "{{ dimension.raw_name }}"
							({{ dimension.categories.map(c=>c.value).join(", ") }})
						</div>`
				},

			},

			template: `
				<ul class="list-group">
					<TransitionGroup name="list">
					<li v-for="(dim, dimIdx) in ui_state.currentGrid.dimensions" class="list-group-item" :key="dim.name">
						<form class="container-fluid needs-validation"><div class="row">
							<div class="dimension-buttons d-inline-flex flex-row flex-md-column col-md-2">
								<template v-if="dim.name==ui_state.editingDimName">
									<button type="button" class="btn btn-outline-primary mb-1" @click="editDimension_abort">Cancel</button>
									<button type="button" class="btn btn-outline-primary mb-1" @click="removeDimension(dimIdx)">Delete</button>
									<button type="button" class="btn btn-outline-primary mb-1" @click="editDimension_end">Save</button>
								</template>
								<template v-else>
									<button type="button" class="btn btn-secondary mb-1 bi bi-pencil" @click="editDimension_start($event, dim.name)"></button>
									<button type="button" class="btn btn-secondary mb-1 bi bi-caret-up-fill" @click="moveDimension(dimIdx,-1)" :disabled="!isMovable(dimIdx,-1)"></button>
									<button type="button" class="btn btn-secondary mb-1 bi bi-caret-down-fill" @click="moveDimension(dimIdx,+1)" :disabled="!isMovable(dimIdx,+1)"></button>
								</template>
							</div>
							<div class="col-10">
								<component :is="dim.type+'Dimension'"
									:dimension="dim" :ui_state="ui_state"></component>
							</div>
						</div></form>
					</li>
					</TransitionGroup>
					<li class="list-group-item">
						<div class="d-flex justify-content-start align-items-baseline">
							<button class="btn btn-secondary" @click="newDimension">
								Ajouter une dimension
							</button>
							<div class="mx-1"> de type </div>
							<select class="form-select w-auto" v-model="newDimType">
								<option disabled value="">Type de dimension</option>
								<option value="ThresholdCategory">Par seuil</option>
								<option value="EnumCategory">Par énumération</option>
								<option value="DirectCategory">Directe</option>
							</select>
						</div>
					</li>

				</ul>
			`
		};


		var PricingGrids_GridCell = {
			props: {
				cell: Object
			},
			emits: ["editGridCell"],
			template: `
				<div class="gridCell">
					<a class="position-absolute top-0 end-0" data-bs-toggle="modal" data-bs-target="#grid-cell-customizer"
					  @click="$emit('editGridCell', cell)">
						<i class="bi bi-pencil-square"></i>
					</a>
					<template v-if="cell">
						<template v-if="cell.policy">
							<pricinggrids-policyQuick :policy="cell.policy" />
						</template>
						<template v-else>
							<span class="badge text-bg-warning">EMPTY</span>
						</template>
					</template>
					<template v-else>
						<span class="badge text-bg-danger">NO CELL</span><!-- error case -->
					</template>
				</div>
				`
		};

		var PricingGrids_Policy = {
			props: {
				policy: Object,
				ui_state: Object,
				editMode: String, // among "full", "quick", "no"
			},
			data(){
				return {
					numericRawCoords,
					stringRawCoords
				}
			},
			methods:{
				toggleOffset(){
					if (this.policy.type != "PerVolumePrice") return;
					if (this.policy.offset){
						delete this.policy.offset;
					} else {
						this.policy.offset = {attribute:0, price:0};
					}
				}
			},
			template: '#PricingGrids_Policy-template' // template is shared !
		};

		/* a lighter version of PricingGrids_Policy, with less bindings */
		var PricingGrids_PolicyQuick = {
			props: {
				policy: Object
			},
			data(){
				return {
					editMode: "quick"
				}
			},
			template: '#PricingGrids_Policy-template' // template is shared !
		};


		var PricingGrids_Grid = {
			props: {
				ui_state: Object
			},
			computed:{
				grid(){
					return this.ui_state.currentGrid;
				},
				dimensionCount(){
					return this.ui_state.currentGrid.dimensions.length;
				}
			},
			methods:{
				editGridCell_clear(){
					const modal = document.getElementById("grid-cell-customizer");
					const form = modal.querySelector("form.needs-validation");
					form.classList.remove('was-validated');
				},

				editGridCell_start(cell){
					//this.editGridCell_clear();

					this.ui_state.editingPolicyCell = cell;

					if (cell && cell.policy){
						// Normal cells
						this.ui_state.editingPolicyChoice = cell.policy.type;
						if (this.ui_state.editingPolicyChoice == "clipboardPolicy") throw new Error("'clipboardPolicy' is not a standard Cell Policy !");

						this.ui_state.editingPolicyCopies[cell.policy.type] = deepClone(cell.policy)
					} else {
						// Empty Cells and Policies
						this.ui_state.editingPolicyChoice = "clipboardPolicy";
					}
				},

				editGridCell_end(event){
					if (!this.ui_state.editingPolicyCell) return new Error("Saving cannot occur in a missing Cell.");
					if (!this.ui_state.editingPolicyChoice) throw new Error("Saving cannot occur without a editingPolicyChoice ?!");

					let form = event.target.closest("form.needs-validation");
					if (!form.checkValidity()) {
						event.preventDefault();
						event.stopPropagation();
						form.classList.add('was-validated')
						return;
					}

					let srcPolicy = this.ui_state.editingPolicyCopies[this.ui_state.editingPolicyChoice]
					this.ui_state.editingPolicyCell.policy = deepClone(srcPolicy);

					const modal = document.getElementById("grid-cell-customizer");
					const bsModal = bootstrap.Modal.getOrCreateInstance(modal);
					bsModal.hide();
				},

				editGridCell_emptyClipboard(){
					this.ui_state.editingPolicyCopies['clipboardPolicy'] = null;
				},
				editGridCell_copy(){
					let cell = this.ui_state.editingPolicyCell;
					if (cell && cell.policy) {
						this.ui_state.editingPolicyCopies["clipboardPolicy"] = deepClone(cell.policy);
						this.ui_state.editingPolicyChoice = "clipboardPolicy";
					} //else just ignore
				},
				editGridCell_paste(){
					let srcPolicy = this.ui_state.editingPolicyCopies["clipboardPolicy"];
					if (srcPolicy && srcPolicy.type){
						let dstPolicy = this.ui_state.editingPolicyCopies[srcPolicy.type];
						Object.assign(dstPolicy, srcPolicy);
						this.ui_state.editingPolicyChoice = srcPolicy.type;
					} // else just ignore
				},

				editGridCell_pasteAndSave(event){
					this.editGridCell_paste();
					this.editGridCell_end(event);
				},

				/* "Pretty" category labels (parameterized computed) TODO to be extended */
				categoryLabel(dimension, category, categoryIndex){
					let label;
					switch (dimension.type) {
						case "ThresholdCategory":
							let nextCategory = categoryIndex < dimension.categories.length - 1
							 ? dimension.categories[categoryIndex+1]
							 : null;
							 switch (dimension.raw_name){
								case "poids" :
								case "poidsVolumique": {
									if ((dimension.comparison ?? "eqSup") == "eqSup"){
										label = nextCategory
										? `${category.value} - ${nextCategory.value} kg`
										: `${category.value}+ kg`;
									} else {// == "strictSup"
										label = nextCategory
										? `jusqu'à ${nextCategory.value} kg`
										: `au-delà de ${category.value} kg`;
									}
								} break;
								case "poidsEntier": {
									label = nextCategory
									 ? `${category.value} - ${nextCategory.value - 1} kg`
									 : `${category.value}+ kg`;
								} break;
								default: {
									if ((dimension.comparison ?? "eqSup") == "eqSup"){
										label = nextCategory
										? `[${category.value} - ${nextCategory.value}[`
										: `[${category.value}, +∞[`;
									} else {// == "strictSup"
										label = nextCategory
										? `jusqu'à ${nextCategory.value}`
										: `au-delà de ${category.value}`;
									}
								}

							 }

						case "EnumCategory":
						case "DirectCategory":
						default:
					}
					return label ?? category.value;
				}
			},

			mounted(){
				const modal = document.getElementById("grid-cell-customizer");
				modal.addEventListener('hidden.bs.modal', (event) => {
					this.editGridCell_clear();
				});
			},

			template: '#PricingGrids_Grid-template'
		};




		var PricingTest_Form = {
			props: {
				ui_state: Object
			},
			computed:{
				testResult(){
					if (!this.ui_state.currentGrid) return;
					const gridName = this.ui_state.currentGrid.name;
					const testPricedObj = this.ui_state.testPricedObj;
					return this.ui_state.system.applyGrid(gridName, testPricedObj);
					//return {amount:-1, extra_info:""} //TODO prévoir débrayage pour les références circulaires, au niveau GRID.JS
				}
			},
			template: '#PricingTest-Form-template'
		};

		/**
		 * Table rows based on PricingSystem.apply()'s result.
		 * It is *recursive* because of the nested results.
		 */
		var PricingTest_Result = {
			props: {
				result: Object
			},
			methods:{
				/* render a pretty print JSON coords, to be displayed in a PRE element */
				pretty_coords(coords){
					// btw, if you want "pretty labels" on that, you will need to make the grids interpret their own dimensions...
					let str = JSON.stringify(coords, null, 1);
					str = str.substring(2, str.length-2); // removes the braces and line breaks
					return str;
				}
			},
			template: '#PricingTest-Result-template'
		};


		/** Splitting to array */
		var SplittingInput = {
			props: {
				modelValue: Array,
				modelModifiers: { default: () => ({}) } //capture and ignore this.modelModifiers
			},
			emits: ['update:modelValue'],
			computed: {
				value: {
					get() {
						return this.modelValue.join(" ; ");
					},
					set(value) {
						let arrValue =  value.split(";").map(s => s.trim());
						// cannot sort nor remove empty tokens
						// unless you .lazy the v-model in template
						this.$emit('update:modelValue', arrValue);
					}
				}
			},
			template: `<input v-model="value" />`
		};


		gridBuilderApp.component("audit-info", AuditingInfoRenderer);
		gridBuilderApp.component("text-tags", TextTagsComponent);

		gridBuilderApp.component("money-input", MoneyInput);
		gridBuilderApp.component("splitting-input", SplittingInput);

		gridBuilderApp.component("pricinggrids-tabs", PricingGrids_Tabs);

		gridBuilderApp.component("pricinggrids-grid", PricingGrids_Grid);
		gridBuilderApp.component("pricinggrids-gridcell", PricingGrids_GridCell);

		gridBuilderApp.component("pricinggrids-policy", PricingGrids_Policy);
		gridBuilderApp.component("pricinggrids-policyQuick", PricingGrids_PolicyQuick);


		gridBuilderApp.component("pricinggrids-dim-list", PricingGrids_DimensionList);


		gridBuilderApp.component("pricingtest-form", PricingTest_Form);
		gridBuilderApp.component("pricingtest-result", PricingTest_Result);

		gridBuilderApp.mount('#pricinggrids-builder');
	</script>

</body>



</html>

