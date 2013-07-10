<!--- Revoke access --->
<cfset revokeAccess = application.objGA.revokeAccess() />
<cflocation url="index.cfm?reinit=1" addtoken="false" />