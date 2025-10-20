<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

	<title>Liste des transporteurs</title>

	<%@ include file="/libs/header-inc/client-stack.jspf" %>

	<%@ include file="/libs/header-inc/vue-entityDataGrid.jspf" %>
  </head>
  <body>
	<style>

		table#carrier-grid thead {
		  	position: sticky;
			top: 0; /* Don't forget this, required for the stickiness */
			box-shadow: 0px 8px 10px 0px rgba(0, 0, 0, 0.4);
			z-index:3;
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
	<%@ include file="/libs/body-inc/bs-confirmDialog.jspf" %>


	<H1>BILI</H1>
	<div id="app">
		<entity-data-grid id="carrier-grid" resource-uri="carriers" identifier="name"></entity-data-grid>
	</div>

	<!-- =========================================================== -->
	<!-- =============== Vue components ============================ -->

	<!-- ========== (some) component templates ============== -->







	<!-- ========== component logic ============== -->
	<script type="module">

		/* shared state for the page */
		const app = Vue.createApp({

		});






		app.component("entity-data-grid", EntityDataGrid);
		app.mount('#app');
	</script>

</body>



</html>
