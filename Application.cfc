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
					
			<cfset application.objGA = new com.coldfumonkeh.GoogleAnalytics(
						client_id		=	'772265743439-58s3t34rhj9boqfrqscka0q525fg8pdc.apps.googleusercontent.com',
						client_secret	=	'oPOIFjXdr7KcSdwLMWhvJQyM',
						redirect_uri	=	'http://127.0.0.1:8500/googleanalytics/index.cfm',
						readonly		=	false,
						state			=	'',
						access_type		=	'offline',
						approval_prompt	=	'force'
					) />
			
			<cfset application.objGA.setAccess_token('ya29.AHES6ZTwGq_nIMqiVsUQWmEgQtvBgA7ajPMz4XZ6H9-EPFc') />
			<cfset application.objGA.setRefresh_token('1/bk_imqDTVpELFWHvyRcqHRe-9Y2I83Pt25lymozGf0M') />
			
		<cfreturn true />
	</cffunction>

 
	<cffunction
		name="onRequestStart"
		access="public"
		returntype="boolean"
		output="false"
		hint="Fires at first part of page processing.">
		
			<cfif structKeyExists(URL, 'reinit')>
				<cfif structKeyExists(session, "google_api_auth")>
					<cfset structDelete(session,"google_api_auth")>
				</cfif>
				<cfset onApplicationStart() />
			</cfif>
	
		<cfreturn true />
	</cffunction>
 
</cfcomponent>