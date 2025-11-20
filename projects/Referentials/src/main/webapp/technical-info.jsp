<%@page import="java.util.TimeZone"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>(ComptaTransport)</title>
</head>
<body>
	<H1>Détails techniques</H1>

	<H2>Variables</H2>
	<ul>
		<li><b>TimeZone par défaut de la JVM</b>
			<ul>
				<li><em>Affecte toutes les <b>dates utilisateur</b> (paramètres échangés en WS, colonnes dates en base, etc.)</em></li>
				<li><em>N'affecte pas les <b>dates système (d'audit) stockées</b> (colonnes _date_XXX), qui sont à la TZ du serveur MySQL, UTC à priori</em></li>
				<li><em>N'affecte pas les affichages UI, mais...</em></li>
				<li><em>... devrait être égal à la TZ des postes utilisateurs, car les valeurs échangées entre client et serveur sont en "temps local"</em></li>
				<%-- Note : this is considered a weak design ; JVM shouldn't matter, better use UTC in every storage and data exchange, and use client-local TZ at browser level ONLY --%>
				<li>valeur: <%= TimeZone.getDefault() %></li> 
			</ul>			
	</ul>
</body>
</html>