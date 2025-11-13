<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>(ComptaTransport)</title>
	
	<%@ include file="/WEB-INF/includes/header-inc/client-stack.jspf" %>
	
</head>
<body>
	<H1>(Titre à choisir ;-)</H1>

	<H2>Référentiels</H2>
	<ul>
		<li><a href="<c:url value="/carriers"/> ">Liste de transporteurs</a></li>
		<li><a href="<c:url value="/priceGrids" />">Grilles de frais de port</a></li>
		<li><a href="<c:url value="/customers" />">Clients forfait et autres</a></li>
	</ul>
	
	
	<H2>Contrôles</H2>
	<ul>
		<li>à faire...</li>
	</ul>	
</body>
</html>