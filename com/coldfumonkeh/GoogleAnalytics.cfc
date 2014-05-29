<!---
Name: GoogleAnalytics.cfc
Author: Matt Gifford
Date: 9th January 2013
Purpose: 
	This component interacts with the Google Analytics API to retrieve data for analysis and display.
	The requests require authentication through the OAuth2 protocol, also handled by this component.
	
Reference: https://developers.google.com/analytics/devguides/config/mgmt/v3/

Changelog:

10/07/2013 - Revised structure and split reporting and management into separate objects.
09/07/2013 - Added Management API methods and amended Core Reporting methods
09/01/2013 - Initial release

--->
<cfcomponent output="false" accessors="true" extends="Utils">
	
	<cfproperty name="client_id" 		type="string" />
	<cfproperty name="client_secret" 	type="string" />
	<cfproperty name="redirect_uri" 	type="string" />
	<cfproperty name="readonly" 		type="boolean" />
	<cfproperty name="scope" 			type="string" />
	<cfproperty name="state" 			type="string" />
	<cfproperty name="access_type"		type="string" />
	<cfproperty name="approval_prompt"	type="string" />
	
	<!--- Sub components --->
	<cfproperty name="management"		type="Management" />
	<cfproperty name="reporting"		type="Reporting" />
	
	<!--- Google API Details --->
	<cfproperty name="baseAuthEndpoint"	type="string" />	
	
	<!--- Auth details from the authentication --->
	<cfproperty name="access_token"		type="string" default="" />
	<cfproperty name="refresh_token"	type="string" default="" />
	
	<cffunction name="init" access="public" output="false" hint="The constructor method.">
		<cfargument name="client_id" 				type="string" 	required="true"						hint="Indicates the client that is making the request. The value passed in this parameter must exactly match the value shown in the APIs Console." />
		<cfargument name="client_secret" 			type="string" 	required="true"						hint="The secret key associated with the client." />
		<cfargument name="redirect_uri" 			type="string" 	required="true"						hint="Determines where the response is sent. The value of this parameter must exactly match one of the values registered in the APIs Console (including the http or https schemes, case, and trailing '/')." />
		<cfargument name="readonly"					type="boolean"	required="false" default="true"		hint="Is access authorized for read only or write? This defines the SCOPE sent to the OAuth request." />
		<cfargument name="state" 					type="string" 	required="true"						hint="Indicates any state which may be useful to your application upon receipt of the response. The Google Authorization Server roundtrips this parameter, so your application receives the same value it sent. Possible uses include redirecting the user to the correct resource in your site, nonces, and cross-site-request-forgery mitigations." />
		<cfargument name="access_type" 				type="string" 	required="false" default="online" 	hint="ONLINE or OFFLINE. Indicates if your application needs to access a Google API when the user is not present at the browser. This parameter defaults to online. If your application needs to refresh access tokens when the user is not present at the browser, then use offline. This will result in your application obtaining a refresh token the first time your application exchanges an authorization code for a user." />
		<cfargument name="approval_prompt"			type="string" 	required="false" default="auto" 	hint="AUTO or FORCE. Indicates if the user should be re-prompted for consent. The default is auto, so a given user should only see the consent page for a given set of scopes the first time through the sequence. If the value is force, then the user sees a consent page even if they have previously given consent to your application for a given set of scopes." />
		<cfargument name="baseAuthEndpoint"			type="string" 	required="false" default="https://accounts.google.com/o/oauth2/" 				hint="The base URL to which we will make the OAuth requests." />
		<cfargument name="reportingAPIEndpoint"		type="string" 	required="false" default="https://www.googleapis.com/analytics/v3/data/" 		hint="The base reporting API URL to which we will make the API requests." />
		<cfargument name="managementAPIEndpoint"	type="string" 	required="false" default="https://www.googleapis.com/analytics/v3/management/" 	hint="The base management API URL to which we will make the API requests." />
			<cfset setClient_id(arguments.client_id) />
			<cfset setClient_secret(arguments.client_secret) />
			<cfset setRedirect_uri(arguments.redirect_uri) />
			<cfset manageScope(arguments.readonly) />
			<cfset setState(arguments.state) />
			<cfset setAccess_type(arguments.access_type) />
			<cfset setBaseAuthEndpoint(arguments.baseAuthEndpoint) />
			<cfset setManagement(createObject("component","Management").init(arguments.managementAPIEndpoint)) />
			<cfset setReporting(createObject("component","Reporting").init(arguments.reportingAPIEndpoint)) />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="manageScope" access="public" output="false" hint="I set the correct scope URL based upon the readonly value.">
		<cfargument name="readonly" required="true" type="boolean" hint="The readonly value sent through the init method." />
			<cfset var strScopeURL = "https://www.googleapis.com/auth/analytics" />
			<cfif readonly>
				<cfset strScopeURL = strScopeURL & ".readonly" />				
			</cfif>
		<cfset setScope(strScopeURL) />
	</cffunction>
	
	<!--- ****************************** --->
	<!--- START OAuth and access methods --->
	<!--- ****************************** --->
		
	<cffunction name="getLoginURL" access="public" output="false" returntype="String" hint="I generate the link to login and retrieve the authentication code.">
		<cfset var strLoginURL = "" />
			<cfset strLoginURL = getBaseAuthEndpoint() 
				& "auth?scope=" & getScope() 
                & "&redirect_uri=" & getRedirect_uri()
                & "&response_type=code&client_id=" & getClient_id()
                & "&access_type=" & getAccess_type() />
		<cfreturn strLoginURL />
	</cffunction>
	
	<cffunction name="getAccessToken" access="public" output="false" returntype="Struct" hint="This method exchanges the authorization code for an access token and (where present) a refresh token.">
		<cfargument name="code" type="string" required="yes" hint="The returned authorization code." />
			<cfset var strURL = getBaseAuthEndpoint() & "token" />
				<cfhttp url="#strURL#" method="post">
		       		<cfhttpparam name="code" 			type="formField" value="#arguments.code#" />
		       		<cfhttpparam name="client_id" 		type="formField" value="#getClient_id()#" />
		       		<cfhttpparam name="client_secret" 	type="formField" value="#getClient_secret()#" />
		       		<cfhttpparam name="redirect_uri" 	type="formField" value="#getRedirect_uri()#" />
		       		<cfhttpparam name="grant_type" 		type="formField" value="authorization_code" />
				</cfhttp>
		<cfreturn manageResponse(cfhttp.FileContent) />
	</cffunction>
	
	<cffunction name="refreshToken" access="public" output="false" hint="I take the refresh_token from the authorization procedure and get you a new access token.">
		<cfset var strURL = getBaseAuthEndpoint() & "token" />
			<cfhttp url="#strURL#" method="post">
	       		<cfhttpparam name="refresh_token" 		type="formField" value="#getRefresh_token()#" />
	       		<cfhttpparam name="client_id" 			type="formField" value="#getClient_id()#" />
	       		<cfhttpparam name="client_secret" 		type="formField" value="#getClient_secret()#" />
	       		<cfhttpparam name="grant_type" 			type="formField" value="refresh_token" />
			</cfhttp>
		<cfreturn manageResponse(cfhttp.FileContent) />
	</cffunction>
	
	<cffunction name="revokeAccess" access="public" output="false" hint="I revoke access to this application. You must pass in either the refresh token or access token.">
		<cfargument name="token" type="string" required="true" default="#getAccess_token()#" hint="The access token or refresh token generated from the successful OAuth authentication process." />
    		<cfset var strURL = getBaseAuthEndpoint() & "revoke?token=" & arguments.token />		
			<cfhttp url="#strURL#" />
		<cfreturn cfhttp />
	</cffunction>
	
	<!--- **************************** --->
	<!--- END OAuth and access methods --->
	<!--- **************************** --->
		
	<!--- ******************************** --->
	<!--- START Core Reporting API Methods --->
	<!--- ******************************** --->
		
	<cffunction name="getProfileData" access="public" output="false" returntype="Struct" hint="I return data for the selected profile.">
		<cfargument name="profileID" 	required="true" type="string" 													hint="The analytics profile ID." />
		<cfargument name="start_date" 	required="true" type="string" 	default="#DateFormat(Now()-7, "yyyy-mm-dd")#"	hint="The first date of the date range for which you are requesting the data." />
		<cfargument name="end_date" 	required="true" type="string" 	default="#DateFormat(Now(), "yyyy-mm-dd")#"		hint="The last date of the date range for which you are requesting the data." />
		<cfargument name="access_token" required="true"	type="string" 	default="#getAccess_token()#" 					hint="The access token generated from the successful OAuth authentication process." />
		<cfreturn getReporting().getProfileData(argumentCollection=arguments) />
	</cffunction>
	
	<cffunction name="getPageVistsForURI" access="public" output="false" returntype="Struct" hint="I return page visit statistics within the given date range for a particular URI.">
		<cfargument name="profileID" 	required="true" 	type="string" 													hint="The analytics profile ID." />
		<cfargument name="start_date" 	required="true" 	type="string" 	default="#DateFormat(Now()-7, "yyyy-mm-dd")#"	hint="The first date of the date range for which you are requesting the data." />
		<cfargument name="end_date" 	required="true" 	type="string"	default="#DateFormat(Now(), "yyyy-mm-dd")#"		hint="The last date of the date range for which you are requesting the data." />
		<cfargument name="uri"			required="true" 	type="string"													hint="The URI to filter for." />
		<cfargument name="start_index" 	required="false" 	type="string" 													hint="The first row of data to retrieve, starting at 1. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="max_results" 	required="false" 	type="string" 													hint="The maximum number of rows to include in the response." />
		<cfargument name="access_token" required="true"		type="string"	default="#getAccess_token()#"					hint="The access token generated from the successful OAuth authentication process." />
		<cfreturn getReporting().getPageVistsForURI(argumentCollection=arguments) />
	</cffunction>
		
	<!---
		Documentation for available dimensions and metrics can be found here:
		https://developers.google.com/analytics/devguides/reporting/core/dimsmets
	--->
		
	<cffunction name="queryAnalytics" access="public" output="false" returntype="Struct" hint="I make a generic request to the Google Analytics API, based upon the parameters you provide me.">
		<cfargument name="profileID" 	required="true" 	type="string" 													hint="The analytics profile ID." />
		<cfargument name="start_date" 	required="true" 	type="string"	default="#DateFormat(Now()-7, "yyyy-mm-dd")#" 	hint="The first date of the date range for which you are requesting the data." />
		<cfargument name="end_date" 	required="true" 	type="string" 	default="#DateFormat(Now(), "yyyy-mm-dd")#"		hint="The last date of the date range for which you are requesting the data." />
		<cfargument name="metrics" 		required="true" 	type="string" 	default="ga:sessions,ga:bounces"				hint="A list of comma-separated metrics, such as ga:sessions,ga:bounces." />
		<cfargument name="dimensions" 	required="false"	type="string"													hint="A list of comma-separated dimensions for your Analytics data, such as ga:browser,ga:city." />
		<cfargument name="sort" 		required="false" 	type="string" 													hint="A list of comma-separated dimensions and metrics indicating the sorting order and sorting direction for the returned data." />
		<cfargument name="filters" 		required="false" 	type="string" 													hint="Dimension or metric filters that restrict the data returned for your request." />
		<cfargument name="segment" 		required="false" 	type="string" 													hint="Segments the data returned for your request." />
		<cfargument name="start_index" 	required="false" 	type="string" 													hint="The first row of data to retrieve, starting at 1. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="max_results" 	required="false" 	type="string" 													hint="The maximum number of rows to include in the response." />
		<cfargument name="fields" 		required="false" 	type="string" 													hint="Selector specifying a subset of fields to include in the response." />
		<cfargument name="prettyPrint" 	required="false" 	type="string" 													hint="Returns response with indentations and line breaks. Default false." />
		<cfargument name="access_token" required="true"		type="string"	default="#getAccess_token()#"					hint="The access token generated from the successful OAuth authentication process." />
			<cfset arguments.reportType	= "ga" />
		<cfreturn getReporting().queryAnalytics(argumentCollection=arguments) />
	</cffunction>
		
	<!--- ****************************** --->
	<!--- END Core Reporting API Methods --->
	<!--- ****************************** --->
		
	<!--- ************************************************* --->
	<!--- START Multi-Channel Funnels Reporting API Methods --->
	<!--- ************************************************* --->
		
	<!---
		Documentation for available dimensions and metrics can be found here:
		https://developers.google.com/analytics/devguides/reporting/mcf/dimsmets/	
	--->
	
	<cffunction name="queryMCFAnalytics" access="public" output="false" returntype="Struct" hint="I make a generic request to the Google Analytics API, based upon the parameters you provide me.">
		<cfargument name="profileID" 	required="true" 	type="string" 																hint="The analytics profile ID." />
		<cfargument name="start_date" 	required="true" 	type="string"	default="#DateFormat(Now()-7, "yyyy-mm-dd")#" 				hint="The first date of the date range for which you are requesting the data." />
		<cfargument name="end_date" 	required="true" 	type="string" 	default="#DateFormat(Now(), "yyyy-mm-dd")#"					hint="The last date of the date range for which you are requesting the data." />
		<cfargument name="metrics" 		required="true" 	type="string" 	default="mcf:totalConversions,mcf:totalConversionValue"		hint="A list of comma-separated metrics, such as mcf:totalConversions,mcf:totalConversionValue." />
		<cfargument name="dimensions" 	required="false"	type="string"	default="mcf:source,mcf:keyword"							hint="A list of comma-separated dimensions for your Analytics data, such as mcf:source,mcf:keyword." />
		<cfargument name="sort" 		required="false" 	type="string" 																hint="A list of comma-separated dimensions and metrics indicating the sorting order and sorting direction for the returned data." />
		<cfargument name="filters" 		required="false" 	type="string" 																hint="Dimension or metric filters that restrict the data returned for your request." />
		<cfargument name="start_index" 	required="false" 	type="string" 																hint="The first row of data to retrieve, starting at 1. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="max_results" 	required="false" 	type="string" 																hint="The maximum number of rows to include in the response." />
		<cfargument name="access_token" required="true"		type="string"	default="#getAccess_token()#"								hint="The access token generated from the successful OAuth authentication process." />
			<cfset arguments.reportType	= "mcf" />
		<cfreturn getReporting().queryAnalytics(argumentCollection=arguments) />
	</cffunction>	
	
	<!--- *********************************************** --->
	<!--- END Multi-Channel Funnels Reporting API Methods --->
	<!--- *********************************************** --->
		
	<!--- **************************** --->
	<!--- START Management API Methods --->
	<!--- **************************** --->
			
	<!--- START Management.accounts --->
	<cffunction name="listAccounts" access="public" output="false" hint="I return all accounts to which the authorized user has access.">
		<cfargument name="max_results" 	required="false" type="numeric" 								hint="The maximum number of accounts to include in this response." />
		<cfargument name="start_index" 	required="false" type="numeric" 								hint="An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" required="true"  type="string" 	default="#getAccess_token()#" 	hint="The access token generated from the successful OAuth authentication process." />
		<cfreturn getManagement().listAccounts(argumentCollection=arguments) />
	</cffunction>
	<!--- END Management.accounts --->
		
	<!--- START Management.webproperties --->
	<cffunction name="listWebProperties" access="public" output="false" hint="I return all web properties to which the authorized user has access.">
		<cfargument name="accountID" 	required="true" 	type="string" 									hint="Account ID to retrieve web properties for. Can either be a specific account ID or '~all', which refers to all the accounts that user has access to." />
		<cfargument name="max_results" 	required="false" 	type="numeric" 									hint="The maximum number of accounts to include in this response." />
		<cfargument name="start_index" 	required="false" 	type="numeric" 									hint="An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" required="true"  	type="string" 	default="#getAccess_token()#" 	hint="The access token generated from the successful OAuth authentication process." />
    	<cfreturn getManagement().listWebProperties(argumentCollection=arguments) />
	</cffunction>
	<!--- END Management.webproperties --->
		
	<!--- START Management.profiles --->
	<cffunction name="listProfiles" access="public" output="false" hint="I return all profiles to which the authorized user has access.">
		<cfargument name="accountId" 		required="true" 	type="string" 									hint="Account ID to retrieve web properties for. Can either be a specific account ID or '~all', which refers to all the accounts that user has access to." />
		<cfargument name="webPropertyId" 	required="true" 	type="string" 									hint="Web property ID for the profiles to retrieve. Can either be a specific web property ID or '~all', which refers to all the web properties to which the user has access." />
		<cfargument name="max_results" 		required="false" 	type="numeric" 									hint="The maximum number of accounts to include in this response." />
		<cfargument name="start_index" 		required="false" 	type="numeric" 									hint="An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" 	required="true"  	type="string" 	default="#getAccess_token()#" 	hint="The access token generated from the successful OAuth authentication process." />
    	<cfreturn getManagement().listProfiles(argumentCollection=arguments) />
	</cffunction>	
	<!--- END Management.profiles --->
			
	<!--- START Management.goals --->
	<cffunction name="listGoals" access="public" output="false" hint="I return all goals to which the authorized user has access.">
		<cfargument name="accountId" 		required="true" 	type="string" 									hint="Account ID to retrieve web properties for. Can either be a specific account ID or '~all', which refers to all the accounts that user has access to." />
		<cfargument name="webPropertyId" 	required="true" 	type="string" 									hint="Web property ID for the profiles to retrieve. Can either be a specific web property ID or '~all', which refers to all the web properties to which the user has access." />
		<cfargument name="profileId" 		required="true" 	type="string" 									hint="Profile ID to retrieve goals for. Can either be a specific profile ID or '~all', which refers to all the profiles that user has access to." />
		<cfargument name="max_results" 		required="false" 	type="numeric" 									hint="The maximum number of accounts to include in this response." />
		<cfargument name="start_index" 		required="false" 	type="numeric" 									hint="An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" 	required="true"  	type="string" 	default="#getAccess_token()#" 	hint="The access token generated from the successful OAuth authentication process." />
    	<cfreturn getManagement().listGoals(argumentCollection=arguments) />
	</cffunction>	
	<!--- END Management.goals --->
			
	<!--- START Management.segments --->
	<cffunction name="listSegments" access="public" output="false" hint="I return all advanced segments to which the authorized user has access.">
		<cfargument name="accountId" 		required="true" 	type="string" 									hint="Account ID to retrieve web properties for. Can either be a specific account ID or '~all', which refers to all the accounts that user has access to." />
		<cfargument name="webPropertyId" 	required="true" 	type="string" 									hint="Web property ID for the profiles to retrieve. Can either be a specific web property ID or '~all', which refers to all the web properties to which the user has access." />
		<cfargument name="max_results" 		required="false" 	type="numeric" 									hint="The maximum number of accounts to include in this response." />
		<cfargument name="start_index" 		required="false" 	type="numeric" 									hint="An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" 	required="true"  	type="string" 	default="#getAccess_token()#" 	hint="The access token generated from the successful OAuth authentication process." />
    	<cfreturn getManagement().listSegments(argumentCollection=arguments) />
	</cffunction>	
	<!--- END Management.segments --->
		
	<!--- START Management.customDataSources --->
	<cffunction name="listCustomDataSources" access="public" output="false" hint="I return all advanced segments to which the authorized user has access.">
		<cfargument name="accountId" 		required="true" 	type="string" 									hint="Account ID to retrieve web properties for. Can either be a specific account ID or '~all', which refers to all the accounts that user has access to." />
		<cfargument name="webPropertyId" 	required="true" 	type="string" 									hint="Web property ID for the profiles to retrieve. Can either be a specific web property ID or '~all', which refers to all the web properties to which the user has access." />
		<cfargument name="max_results" 		required="false" 	type="numeric" 									hint="The maximum number of accounts to include in this response." />
		<cfargument name="start_index" 		required="false" 	type="numeric" 									hint="An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" 	required="true"  	type="string" 	default="#getAccess_token()#" 	hint="The access token generated from the successful OAuth authentication process." />
    	<cfreturn getManagement().listCustomDatasources(argumentCollection=arguments) />
	</cffunction>	
	<!--- END Management.customDataSources --->
		
	<!--- START Management.dailyUploads --->
	<cffunction name="listDailyUploads" access="public" output="false" hint="I return all advanced segments to which the authorized user has access.">
		<cfargument name="accountId" 			required="true" 	type="string" 									hint="Account ID to retrieve web properties for. Can either be a specific account ID or '~all', which refers to all the accounts that user has access to." />
		<cfargument name="customDataSourceId" 	required="true" 	type="string" 									hint="Custom data source Id for daily uploads to retrieve." />
		<cfargument name="end_date" 			required="false" 	type="string" 									hint="End date of the form YYYY-MM-DD." />
		<cfargument name="start_date" 			required="false" 	type="string" 									hint="Start date of the form YYYY-MM-DD." />
		<cfargument name="webPropertyId" 		required="true" 	type="string" 									hint="Web property ID for the daily uploads to retrieve." />
		<cfargument name="max_results" 			required="false" 	type="numeric" 									hint="The maximum number of accounts to include in this response." />
		<cfargument name="start_index" 			required="false" 	type="numeric" 									hint="An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" 		required="true"  	type="string" 	default="#getAccess_token()#" 	hint="The access token generated from the successful OAuth authentication process." />
    	<cfreturn getManagement().listDailyUploads(argumentCollection=arguments) />
	</cffunction>
	<!--- END Management.dailyUploads --->
		
	<!--- START Management.experiments --->
	<cffunction name="listExperiments" access="public" output="false" hint="">
		<cfargument name="accountID" 		required="true" 	type="string" 									hint="The analytics account ID." />
		<cfargument name="webPropertyID" 	required="true" 	type="string" 									hint="The analytics web property ID." />
		<cfargument name="profileID" 		required="true" 	type="string" 									hint="The analytics profile ID." />
		<cfargument name="max_results" 		required="false" 	type="numeric" 									hint="The maximum number of experiments to include in this response." />
		<cfargument name="start_index" 		required="false" 	type="numeric" 									hint="An index of the first experiment to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" 	required="true"		type="string"	default="#getAccess_token()#"	hint="The access token generated from the successful OAuth authentication process." />
		<cfreturn getManagement().listExperiments(argumentCollection=arguments) />
	</cffunction>
	
	<cffunction name="getExperiment" access="public" output="false" hint="">
		<cfargument name="accountId" 		required="true" 	type="string" 													hint="The analytics account ID." />
		<cfargument name="webPropertyId" 	required="true" 	type="string" 													hint="The analytics web property ID." />
		<cfargument name="profileID" 		required="true" 	type="string" 													hint="The analytics profile ID." />
		<cfargument name="experimentID" 	required="true" 	type="string" 													hint="The analytics experiment ID." />
		<cfargument name="access_token" 	required="true"		type="string"	default="#getAccess_token()#"					hint="The access token generated from the successful OAuth authentication process." />
		<cfreturn getManagement().getExperiment(argumentCollection=arguments) />	
	</cffunction>
	
	<cffunction name="insertExperiment" access="public" output="false" hint="I insert a new experiment for the authorized user.">
		<cfargument name="accountId" 						required="true" 	type="string" 									hint="The analytics account ID." />
		<cfargument name="webPropertyId" 					required="true" 	type="string" 									hint="The analytics web property ID." />
		<cfargument name="profileID" 						required="true" 	type="string" 									hint="The analytics profile ID." />
		<cfargument name="access_token" 					required="true"		type="string"	default="#getAccess_token()#"	hint="The access token generated from the successful OAuth authentication process." />
		<cfargument name="name"								required="true"		type="string"									hint="Experiment name. This field may not be changed for an experiment whose status is ENDED. This field is required when creating an experiment." />
		<cfargument name="status"							required="true"		type="string"									hint="Experiment status. Possible values: DRAFT, READY_TO_RUN, RUNNING. This field is required when creating an experiment." />
		<cfargument name="description"						required="false"	type="string"									hint="Notes about the experiment." />
		<cfargument name="editableInGaUi"					required="false" 	type="boolean" 	default="true"					hint="If true, the end user will be able to edit the experiment via the Google Analytics user interface." /> 
		<cfargument name="minimumExperimentLengthInDays" 	required="false" 	type="numeric" 									hint="Specifies the minimum length of the experiment. Can be changed for a running experiment. This field may not be changed for an experiments whose status is ENDED." /> 
		<cfargument name="objectiveMetric"					required="false"	type="string"									hint="The metric that the experiment is optimizing. Valid values: ga:goal(n)Completions, ga:bounces, ga:pageviews, ga:timeOnSite, ga:transactions, ga:transactionRevenue. This field is required if status is RUNNING and servingFramework is one of REDIRECT or API." />
		<cfargument name="optimizationType"					required="false"	type="string"	default="MAXIMUM"				hint="Whether the objectiveMetric should be minimized or maximized. Possible values: MAXIMUM, MINIMUM. Optional--defaults to MAXIMUM. Cannot be specified without objectiveMetric. Cannot be modified when status is RUNNING or ENDED." />
		<cfargument name="rewriteVariationUrlsAsOriginal" 	required="false" 	type="boolean" 									hint="Boolean specifying whether variations URLS are rewritten to match those of the original. This field may not be changed for an experiments whose status is ENDED." />
		<cfargument name="servingFramework"					required="false"	type="string"									hint="The framework used to serve the experiment variations and evaluate the results. One of: REDIRECT: Google Analytics redirects traffic to different variation pages, reports the chosen variation and evaluates the results. API: Google Analytics chooses and reports the variation to serve and evaluates the results; the caller is responsible for serving the selected variation. EXTERNAL: The variations will be served externally and the chosen variation reported to Google Analytics. The caller is responsible for serving the selected variation and evaluating the results." />
		<cfargument name="trafficCoverage"					required="false"	type="numeric" 									hint="A floating-point number between 0 and 1. Specifies the fraction of the traffic that participates in the experiment. Can be changed for a running experiment. This field may not be changed for an experiments whose status is ENDED." /> 
		<cfargument name="variations"						required="false"	type="array"									hint="Array of variations. The first variation in the array is the original. The number of variations may not change once an experiment is in the RUNNING state. At least two variations are required before status can be set to RUNNING." />		
		<cfargument name="winnerConfidenceLevel" 			required="false"	type="numeric"									hint="A floating-point number between 0 and 1. Specifies the necessary confidence level to choose a winner. This field may not be changed for an experiments whose status is ENDED." />
		<cfreturn getManagement().insertExperiment(argumentCollection=arguments) /> 
	</cffunction>
	<!--- END Management.experiments --->
	
	<!--- ************************** --->
	<!--- END Management API Methods --->
	<!--- ************************** --->
	
</cfcomponent>