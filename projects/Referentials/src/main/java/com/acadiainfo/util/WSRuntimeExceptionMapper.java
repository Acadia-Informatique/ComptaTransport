package com.acadiainfo.util;


import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;

@jakarta.ws.rs.ext.Provider
public class WSRuntimeExceptionMapper implements ExceptionMapper<RuntimeException> {
	private static final java.util.logging.Logger logger
	 = java.util.logging.Logger.getLogger(WSRuntimeExceptionMapper.class.getName());

	@Override
	public Response toResponse(RuntimeException exc) {
		logger.finer("Intercepted exception : " + exc.getClass() + " - message=" + exc.getMessage());
		
		int responseStatus;
		String responseMessage;

		if (exc instanceof jakarta.ws.rs.WebApplicationException) {
			Response webappResponse = ((jakarta.ws.rs.WebApplicationException) exc).getResponse();
			
			responseStatus = webappResponse.getStatus(); 
			responseMessage = exc.getMessage(); // webappResponse.getEntity is changed with <error-pages> in web.xml
		} else {
			Throwable t  = (exc instanceof jakarta.ejb.EJBException)
			  ? ExceptionUtils.unwrapEjbException((jakarta.ejb.EJBException) exc) 
			  : exc;
			
			responseStatus = Response.Status.INTERNAL_SERVER_ERROR.getStatusCode();
			responseMessage = t.getMessage();
		}
		
		return Response.status(responseStatus)
		  .entity(responseMessage)
		  .type(MediaType.TEXT_PLAIN_TYPE.withCharset("UTF-8"))
		  .language(java.util.Locale.ENGLISH) // so sorry ;-)
		  .build();
	}

}
