<%@page import="java.text.DateFormat"%>
<%@page import="java.util.Date"%>
<%@ page isErrorPage="true" 
	language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ACADIA - Développements internes</title>
<style>
 body {
 	background-color:PowderBlue;
 	font-family:sans-serif;
 	margin:50px 100px;
 }
</style>
</head>
<body>
	<h1>Erreur 500</h1>
	<h2>Un problème interne est survenu dans l'application.</h2>
	
	<p>
		<b>Merci de contacter l'informatique interne Acadia</b> :
		<ul>
			<li>avec l'<a href="http://192.168.0.8/glpi/">outil de ticketing IT-helpdesk</a></li>
			<li>sur Microsoft Teams : contactez <code>exploitIT</code></li>
		</ul>
	</p>

			<!-- TODO stabiliser l'URL du ticketing IT-helpdesk -->
	
	<p>
		Afin de faciliter le traitement du problème, vous pouvez leur transmettre les informations suivantes :
		
		<table border="1">
		<thead>
			<tr><th>Paramètre</th><th>Valeur</th></tr>
		</thead>
		<tbody>
			<tr><td>Server</td>        <td><%= request.getServerName()%></td></tr>
			<tr><td>Request URL</td>   <td><%= request.getRequestURL()%></td></tr>
			<tr><td>Query string</td>  <td><%= request.getQueryString()%></td></tr>
			
			<tr><td>Exception</td>     <td><%= exception.getMessage()%></td></tr>
			<tr><td>Server time</td>   <td><%= DateFormat.getDateTimeInstance().format(new Date(System.currentTimeMillis()))  %></td></tr>
			
		</tbody>
		</table>
	</p>		
</body>
</html>


<!-- 

javax.servlet.error.exception
The exception instance that caused the error (or null)

javax.servlet.error.exception_type
The class name of the exception instance that caused the error (or null)

javax.servlet.error.message
The error message.

javax.servlet.error.request_uri
The URI of the errored request.

javax.servlet.error.servlet_name
The Servlet name of the servlet that the errored request was dispatched to/

javax.servlet.error.status_code
 -->
