<cfcomponent output="false">

<!--- Application settings --->
<cfset this.name = "google_analytics_api" />
<cfset this.sessionManagement = true />
<cfset this.sessionTimeout = createTimeSpan(0,2,30,0) />
 
	<cffunction name="onApplicationStart" 
				access="public" 
				returntype="boolean"
				output="false"
				hint="Fires when the application is first created.">
			
			<cftry>		
			<cfif structKeyExists(session, "google_api_auth")>
					<cfset structDelete(session,"google_api_auth")>
			</cfif>
			<cfcatch>
			</cfcatch>
			</cftry>
			<cfset application.objGA = new com.coldfumonkeh.GoogleAnalytics(
						client_id 		=   '< your client id value >',
						client_secret 	= 	'< your client secret value>',
						redirect_uri	=	'http://localhost/googleanalytics/index.cfm',
						state			=	'',
						access_type		=	'online',
						approval_prompt	=	'force'
					) />
			<!---
			<cfset application.objGA.setRefresh_token('< your refresh token value >') />
			<cfset application.objGA.setAccess_token('< your access token value >') />
			--->
		<cfreturn true />
	</cffunction>

 
	<cffunction
		name="onRequestStart"
		access="public"
		returntype="boolean"
		output="false"
		hint="Fires at first part of page processing.">
		
			<cfif structKeyExists(URL, 'reinit')>
				<cfset onApplicationStart() />
			</cfif>
	
		<cfreturn true />
	</cffunction>
 
</cfcomponent>