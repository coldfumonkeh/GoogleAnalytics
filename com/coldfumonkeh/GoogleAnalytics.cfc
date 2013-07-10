<!---
Name: GoogleAnalytics.cfc
Author: Matt Gifford
Date: 9th January 2013
Purpose: 
	This component interacts with the Google Analytics API to retrieve data for analysis and display.
	The requests require authentication through the OAuth2 protocol, also handled by this component.
	
Reference: https://developers.google.com/analytics/devguides/config/mgmt/v3/

Updates:

09/07/2013 - Added Management API methods and amended Core Reporting methods

09/01/2013 - Initial release

--->
<cfcomponent output="false" accessors="true">
	
	<cfproperty name="client_id" 		type="string" />
	<cfproperty name="client_secret" 	type="string" />
	<cfproperty name="redirect_uri" 	type="string" />
	<cfproperty name="scope" 			type="string" />
	<cfproperty name="state" 			type="string" />
	<cfproperty name="access_type"		type="string" />
	<cfproperty name="approval_prompt"	type="string" />
	
	<!--- Google API Details --->
	<cfproperty name="baseAuthEndpoint"			type="string" />
	<cfproperty name="reportingAPIEndpoint"		type="string" />
	<cfproperty name="managementAPIEndpoint"	type="string" />
	
	
	<!--- Auth details from the authentication --->
	<cfproperty name="access_token"		type="string" default="" />
	<cfproperty name="refresh_token"	type="string" default="" />
	
	<cffunction name="init" access="public" output="false" hint="The constructor method.">
		<cfargument name="client_id" 				type="string" required="true"					hint="Indicates the client that is making the request. The value passed in this parameter must exactly match the value shown in the APIs Console." />
		<cfargument name="client_secret" 			type="string" required="true"					hint="The secret key associated with the client." />
		<cfargument name="redirect_uri" 			type="string" required="true"					hint="Determines where the response is sent. The value of this parameter must exactly match one of the values registered in the APIs Console (including the http or https schemes, case, and trailing '/')." />
		<cfargument name="readonly"					type="boolean"required="false" default="true"	hint="Is access authorized for read only or write? This defines the SCOPE sent to the OAuth request." />
		<cfargument name="state" 					type="string" required="true"					hint="Indicates any state which may be useful to your application upon receipt of the response. The Google Authorization Server roundtrips this parameter, so your application receives the same value it sent. Possible uses include redirecting the user to the correct resource in your site, nonces, and cross-site-request-forgery mitigations." />
		<cfargument name="access_type" 				type="string" required="false" default="online" hint="ONLINE or OFFLINE. Indicates if your application needs to access a Google API when the user is not present at the browser. This parameter defaults to online. If your application needs to refresh access tokens when the user is not present at the browser, then use offline. This will result in your application obtaining a refresh token the first time your application exchanges an authorization code for a user." />
		<cfargument name="approval_prompt"			type="string" required="false" default="auto" 	hint="AUTO or FORCE. Indicates if the user should be re-prompted for consent. The default is auto, so a given user should only see the consent page for a given set of scopes the first time through the sequence. If the value is force, then the user sees a consent page even if they have previously given consent to your application for a given set of scopes." />
		<cfargument name="baseAuthEndpoint"			type="string" required="false" default="https://accounts.google.com/o/oauth2/" 					hint="The base URL to which we will make the OAuth requests." />
		<cfargument name="reportingAPIEndpoint"			type="string" required="false" default="https://www.googleapis.com/analytics/v3/data/ga" 		hint="The base URL to which we will make the API requests." />
		<cfargument name="managementAPIEndpoint"	type="string" required="false" default="https://www.googleapis.com/analytics/v3/management/" 	hint="The base management API URL to which we will make the API requests." />
			<cfset setClient_id(arguments.client_id) />
			<cfset setClient_secret(arguments.client_secret) />
			<cfset setRedirect_uri(arguments.redirect_uri) />
			<cfset manageScope(arguments.readonly) />
			<cfset setState(arguments.state) />
			<cfset setAccess_type(arguments.access_type) />
			<cfset setBaseAuthEndpoint(arguments.baseAuthEndpoint) />
			<cfset setReportingAPIEndpoint(arguments.reportingAPIEndpoint) />
			<cfset setManagementAPIEndpoint(arguments.managementAPIEndpoint) />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="manageScope" access="private" output="false" hint="I set the correct scope URL based upon the readonly value.">
		<cfargument name="readonly" required="true" type="boolean" hint="The readonly value sent through the init method." />
			<cfset var strScopeURL = "https://www.googleapis.com/auth/analytics" />
			<cfif readonly>
				<cfset strScopeURL = strScopeURL & ".readonly" />				
			</cfif>
		<cfset setScope(strScopeURL) />
	</cffunction>
	
	<!--- START OAuth and access methods --->
		
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
	
	<cffunction name="manageResponse" access="private" output="false" hint="I take the response from the access and refresh token requests and handle it.">
		<cfargument name="response" required="true" type="Any" hint="The response from the remote request." />
				<cfset var stuResponse 	= {} />
				<cfset var jsonResponse = deserializeJSON(arguments.response) />
				<cfif structKeyExists(jsonResponse, "access_token")>
					<!--- Insert the access token into the properties --->
					<cfset setAccess_token(jsonResponse.access_token) />
					<cfset structInsert(stuResponse, "access_token",	jsonResponse.access_token) />
					<cfset structInsert(stuResponse, "token_type",		jsonResponse.token_type) />
					<cfset structInsert(stuResponse, "expires_in_raw",	jsonResponse.expires_in) />
					<cfset structInsert(stuResponse, "expires_in",		DateAdd("s",jsonResponse.expires_in,Now())) />
					<cfif structKeyExists(jsonResponse, "refresh_token")>
						<cfset structInsert(stuResponse, "refresh_token", jsonResponse.refresh_token) />
						<!--- Insert the refresh token into the properties --->
						<cfset setRefresh_token(jsonResponse.refresh_token) />
					</cfif>
					<cfset structInsert(stuResponse, "success", 		true) />
				<cfelse>
					<cfset structInsert(stuResponse, "access_token",	"Authorization Failed " & cfhttp.filecontent) />
					<cfset structInsert(stuResponse, "success", 		false) />
				</cfif>
		<cfreturn stuResponse />
	</cffunction>
	
	<cffunction name="revokeAccess" access="public" output="false" hint="I revoke access to this application. You must pass in either the refresh token or access token.">
		<cfargument name="token" type="string" required="true" default="#getAccess_token()#" hint="The access token or refresh token generated from the successful OAuth authentication process." />
    		<cfset var strURL = "https://accounts.google.com/o/oauth2/revoke?token=" & arguments.token />		
			<cfhttp url="#strURL#" />
		<cfreturn cfhttp />
	</cffunction>
	
	<!--- END OAuth and access methods --->
		
	
	<!--- START Core Reporting API Methods --->
		
	<cffunction name="getProfileData" access="public" output="false" returntype="Struct" hint="I return data for the selected profile.">
		<cfargument name="profileID" 	required="true" type="string" 								hint="The analytics profile ID." />
		<cfargument name="start_date" 	required="true" type="string" 								hint="The first date of the date range for which you are requesting the data." />
		<cfargument name="end_date" 	required="true" type="string" 								hint="The last date of the date range for which you are requesting the data." />
		<cfargument name="access_token" required="true"	type="string" default="#getAccess_token()#" hint="The access token generated from the successful OAuth authentication process." />
			<cfset var stuResponse = {
				
					"visits_snapshot" 	= queryAnalytics(
												profileID		=	arguments.profileID,
												metrics 		= 	"ga:newVisits,ga:pageviews,ga:visits,ga:visitors,ga:timeOnSite",
												start_date		=	arguments.start_date,
												end_date		=	arguments.end_date,
												access_token	=	arguments.access_token
											),
					"visitor_loyalty" 	= queryAnalytics(
												profileID		=	arguments.profileID,
												dimensions		=	"ga:visitorType",
												metrics 		= 	"ga:visits,ga:organicSearches",
												start_date		=	arguments.start_date,
												end_date		=	arguments.end_date,
												access_token	=	arguments.access_token
											),
					"vists_chart"		= queryAnalytics(
												profileID		=	arguments.profileID,
												dimensions		=	"ga:month,ga:year",
												metrics 		= 	"ga:visits",
												sort			=	"ga:year,ga:month",
												start_date		=	arguments.start_date,
												end_date		=	arguments.end_date,
												access_token	=	arguments.access_token
											),
					"country_chart"		= queryAnalytics(
												profileID		=	arguments.profileID,
												dimensions		=	"ga:country",
												metrics 		= 	"ga:visits",
												sort			=	"-ga:visits",
												start_date		=	arguments.start_date,
												end_date		=	arguments.end_date,
												access_token	=	arguments.access_token
											),
					"top_pages"			= queryAnalytics(
												profileID		=	arguments.profileID,
												dimensions		=	"ga:pageTitle",
												metrics 		= 	"ga:pageviews",
												filters			=	"ga:pageTitle!~Page%20Not%20Found",
												sort			=	"-ga:pageviews",
												start_date		=	arguments.start_date,
												end_date		=	arguments.end_date,
												access_token	=	arguments.access_token
											)} />
		<cfreturn stuResponse />
	</cffunction>
	
	<cffunction name="getPageVistsForURI" access="public" output="false" returntype="Struct" hint="I return page visit statistics within the given date range for a particular URI.">
		<cfargument name="profileID" 	required="true" 	type="string" 													hint="The analytics profile ID." />
		<cfargument name="start_date" 	required="true" 	type="string" 	default="#DateFormat(Now()-7, "yyyy-mm-dd")#"	hint="The first date of the date range for which you are requesting the data." />
		<cfargument name="end_date" 	required="true" 	type="string"	default="#DateFormat(Now(), "yyyy-mm-dd")#"		hint="The last date of the date range for which you are requesting the data." />
		<cfargument name="uri"			required="true" 	type="string"													hint="The URI to filter for." />
		<cfargument name="start_index" 	required="false" 	type="string" 													hint="The first row of data to retrieve, starting at 1. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="max_results" 	required="false" 	type="string" 													hint="The maximum number of rows to include in the response." />
		<cfargument name="access_token" required="true"		type="string"	default="#getAccess_token()#"					hint="The access token generated from the successful OAuth authentication process." />
			<cfset var stuTemp 		= structCopy(arguments) />
				<!--- Remove values we dont want in the URL query string --->
				<cfset structDelete(stuTemp,"uri") />
				<!--- Add in the param values for this method (filter etc) --->
				<cfset structInsert(stuTemp,"dimensions","ga:date,ga:pagepath") />
				<cfset structInsert(stuTemp,"metrics","ga:pageviews") />
				<cfset structInsert(stuTemp,"sort","ga:date,ga:pagepath") />
				<cfset structInsert(stuTemp,"filters","ga:pagepath=~/#arguments.uri#") />
		<cfreturn queryAnalytics(argumentCollection=stuTemp) />
	</cffunction>
		
	<cffunction name="queryAnalytics" access="public" output="false" returntype="Struct" hint="I make a generic request to the Google Analytics API, based upon the parameters you provide me.">
		<cfargument name="profileID" 	required="true" 	type="string" 													hint="The analytics profile ID." />
		<cfargument name="start_date" 	required="true" 	type="string"	default="#DateFormat(Now()-7, "yyyy-mm-dd")#" 	hint="The first date of the date range for which you are requesting the data." />
		<cfargument name="end_date" 	required="true" 	type="string" 	default="#DateFormat(Now(), "yyyy-mm-dd")#"		hint="The last date of the date range for which you are requesting the data." />
		<cfargument name="metrics" 		required="true" 	type="string" 	default="ga:visits,ga:bounces"					hint="A list of comma-separated metrics, such as ga:visits,ga:bounces." />
		<cfargument name="dimensions" 	required="false"	type="string"													hint="A list of comma-separated dimensions for your Analytics data, such as ga:browser,ga:city." />
		<cfargument name="sort" 		required="false" 	type="string" 													hint="A list of comma-separated dimensions and metrics indicating the sorting order and sorting direction for the returned data." />
		<cfargument name="filters" 		required="false" 	type="string" 													hint="Dimension or metric filters that restrict the data returned for your request." />
		<cfargument name="segment" 		required="false" 	type="string" 													hint="Segments the data returned for your request." />
		<cfargument name="start_index" 	required="false" 	type="string" 													hint="The first row of data to retrieve, starting at 1. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="max_results" 	required="false" 	type="string" 													hint="The maximum number of rows to include in the response." />
		<cfargument name="fields" 		required="false" 	type="string" 													hint="Selector specifying a subset of fields to include in the response." />
		<cfargument name="prettyPrint" 	required="false" 	type="string" 													hint="Returns response with indentations and line breaks. Default false." />
		<cfargument name="access_token" required="true"		type="string"	default="#getAccess_token()#"					hint="The access token generated from the successful OAuth authentication process." />
			<cfset var strURL 		= "" />
			<cfset var strParams 	= "" />
			<cfset var stuTemp 		= structCopy(arguments) />
				<!--- Remove values we dont want in the URL query string --->
				<cfset structDelete(stuTemp,"profileID") />
				<cfset structDelete(stuTemp,"access_token") />
				<!--- Build the params and URL --->
				<cfset strParams = buildParamString(clearEmptyParams(stuTemp)) />
				<cfset strURL = getreportingAPIEndpoint() & "?ids=ga:" & arguments.profileID & "&" & strParams />
		<cfreturn makeRequest(remoteURL = strURL, authToken = arguments.access_token) />
	</cffunction>
		
	<!--- END Core Reporting API Methods --->
		
		
	<!--- START Management API Methods --->
		
	<!--- START Management.accounts --->
	<!--- LIST --->
	<!--- GET https://www.googleapis.com/analytics/v3/management/accounts --->	
	<cffunction name="listAccounts" access="public" output="false" hint="I return all accounts to which the authorized user has access.">
		<cfargument name="max_results" 	required="false" type="numeric" 								hint="The maximum number of accounts to include in this response." />
		<cfargument name="start_index" 	required="false" type="numeric" 								hint="An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" required="true"  type="string" 	default="#getAccess_token()#" 	hint="The access token generated from the successful OAuth authentication process." />
    		<cfset var strURL = getManagementAPIEndpoint() & "accounts/" />
			<cfset var stuParams = structCopy(arguments) />
			<cfset var strParams = "" />
				<cfset structDelete(stuParams,"access_token") />
				<cfset strParams = buildParamString(stuParams) />
				<cfif len(strParams)>
					<cfset strURL = strURL & "?" & strParams />
				</cfif>
		<cfreturn makeRequest(strURL, arguments.access_token) />
	</cffunction>
	
	<!--- END Management.accounts --->
		
		
		
	<!--- START Management.webproperties --->
	<!--- LIST --->
	<!--- GET https://www.googleapis.com/analytics/v3/management/accounts/accountId/webproperties --->
	<cffunction name="listWebProperties" access="public" output="false" hint="I return all web properties to which the authorized user has access.">
		<cfargument name="accountID" 	required="true" 	type="string" 									hint="Account ID to retrieve web properties for. Can either be a specific account ID or '~all', which refers to all the accounts that user has access to." />
		<cfargument name="max_results" 	required="false" 	type="numeric" 									hint="The maximum number of accounts to include in this response." />
		<cfargument name="start_index" 	required="false" 	type="numeric" 									hint="An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" required="true"  	type="string" 	default="#getAccess_token()#" 	hint="The access token generated from the successful OAuth authentication process." />
    		<cfset var strURL = getManagementAPIEndpoint() & "accounts/" & arguments.accountID & "/webproperties" />
			<cfset var stuParams = structCopy(arguments) />
			<cfset var strParams = "" />
				<cfset structDelete(stuParams,"accountID") />
				<cfset structDelete(stuParams,"access_token") />
				<cfset strParams = buildParamString(stuParams) />
				<cfif len(strParams)>
					<cfset strURL = strURL & "?" & strParams />
				</cfif>
		<cfreturn makeRequest(strURL, arguments.access_token) />
	</cffunction>
		
	<!--- END Management.webproperties --->
		
		
	
	<!--- START Management.profiles --->
	<!--- LIST --->
	<!--- GET https://www.googleapis.com/analytics/v3/management/accounts/accountId/webproperties/webPropertyId/profiles --->
	<cffunction name="listProfiles" access="public" output="false" hint="I return all profiles to which the authorized user has access.">
		<cfargument name="accountId" 		required="true" 	type="string" 									hint="Account ID to retrieve web properties for. Can either be a specific account ID or '~all', which refers to all the accounts that user has access to." />
		<cfargument name="webPropertyId" 	required="true" 	type="string" 									hint="Web property ID for the profiles to retrieve. Can either be a specific web property ID or '~all', which refers to all the web properties to which the user has access." />
		<cfargument name="max_results" 		required="false" 	type="numeric" 									hint="The maximum number of accounts to include in this response." />
		<cfargument name="start_index" 		required="false" 	type="numeric" 									hint="An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" 	required="true"  	type="string" 	default="#getAccess_token()#" 	hint="The access token generated from the successful OAuth authentication process." />
    		<cfset var strURL = getManagementAPIEndpoint() & "accounts/" & arguments.accountId & "/webproperties/" & arguments.webPropertyId & "/profiles" />
			<cfset var stuParams = structCopy(arguments) />
			<cfset var strParams = "" />
				<cfset structDelete(stuParams,"accountId") />
				<cfset structDelete(stuParams,"webPropertyId") />
				<cfset structDelete(stuParams,"access_token") />
				<cfset strParams = buildParamString(stuParams) />
				<cfif len(strParams)>
					<cfset strURL = strURL & "?" & strParams />
				</cfif>
		<cfreturn makeRequest(strURL, arguments.access_token) />
	</cffunction>
		
	<!--- END Management.profiles --->
		
		
		
	<!--- START Management.goals --->
	<!--- LIST --->
	<!--- GET https://www.googleapis.com/analytics/v3/management/accounts/accountId/webproperties/webPropertyId/profiles/profileId/goals --->
	<cffunction name="listGoals" access="public" output="false" hint="I return all goals to which the authorized user has access.">
		<cfargument name="accountId" 		required="true" 	type="string" 									hint="Account ID to retrieve web properties for. Can either be a specific account ID or '~all', which refers to all the accounts that user has access to." />
		<cfargument name="webPropertyId" 	required="true" 	type="string" 									hint="Web property ID for the profiles to retrieve. Can either be a specific web property ID or '~all', which refers to all the web properties to which the user has access." />
		<cfargument name="profileId" 		required="true" 	type="string" 									hint="Profile ID to retrieve goals for. Can either be a specific profile ID or '~all', which refers to all the profiles that user has access to." />
		<cfargument name="max_results" 		required="false" 	type="numeric" 									hint="The maximum number of accounts to include in this response." />
		<cfargument name="start_index" 		required="false" 	type="numeric" 									hint="An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" 	required="true"  	type="string" 	default="#getAccess_token()#" 	hint="The access token generated from the successful OAuth authentication process." />
    		<cfset var strURL = getManagementAPIEndpoint() & "accounts/" & arguments.accountId & "/webproperties/" & arguments.webPropertyId & "/profiles/" & arguments.profileId & "/goals" />
			<cfset var stuParams = structCopy(arguments) />
			<cfset var strParams = "" />
				<cfset structDelete(stuParams,"accountId") />
				<cfset structDelete(stuParams,"webPropertyId") />
				<cfset structDelete(stuParams,"profileId") />
				<cfset structDelete(stuParams,"access_token") />
				<cfset strParams = buildParamString(stuParams) />
				<cfif len(strParams)>
					<cfset strURL = strURL & "?" & strParams />
				</cfif>
		<cfreturn makeRequest(strURL, arguments.access_token) />
	</cffunction>
	
		
	<!--- END Management.goals --->
		
		
		
	<!--- START Management.segments --->
	<!--- LIST --->
	<!--- GET https://www.googleapis.com/analytics/v3/management/segments --->
	<cffunction name="listSegments" access="public" output="false" hint="I return all advanced segments to which the authorized user has access.">
		<cfargument name="accountId" 		required="true" 	type="string" 									hint="Account ID to retrieve web properties for. Can either be a specific account ID or '~all', which refers to all the accounts that user has access to." />
		<cfargument name="webPropertyId" 	required="true" 	type="string" 									hint="Web property ID for the profiles to retrieve. Can either be a specific web property ID or '~all', which refers to all the web properties to which the user has access." />
		<cfargument name="max_results" 		required="false" 	type="numeric" 									hint="The maximum number of accounts to include in this response." />
		<cfargument name="start_index" 		required="false" 	type="numeric" 									hint="An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" 	required="true"  	type="string" 	default="#getAccess_token()#" 	hint="The access token generated from the successful OAuth authentication process." />
    		<cfset var strURL = getManagementAPIEndpoint() & "segments" />
			<cfset var stuParams = structCopy(arguments) />
			<cfset var strParams = "" />
				<cfset structDelete(stuParams,"access_token") />
				<cfset strParams = buildParamString(stuParams) />
				<cfif len(strParams)>
					<cfset strURL = strURL & "?" & strParams />
				</cfif>
		<cfreturn makeRequest(strURL, arguments.access_token) />
	</cffunction>
	
		
	<!--- END Management.segments --->
		
		
	
	<!--- START Management.customDataSources --->
	<!--- LIST --->
	<!--- GET https://www.googleapis.com/analytics/v3/management/accounts/accountId/webproperties/webPropertyId/customDataSources --->
	<cffunction name="listCustomDataSources" access="public" output="false" hint="I return all advanced segments to which the authorized user has access.">
		<cfargument name="accountId" 		required="true" 	type="string" 									hint="Account ID to retrieve web properties for. Can either be a specific account ID or '~all', which refers to all the accounts that user has access to." />
		<cfargument name="webPropertyId" 	required="true" 	type="string" 									hint="Web property ID for the profiles to retrieve. Can either be a specific web property ID or '~all', which refers to all the web properties to which the user has access." />
		<cfargument name="max_results" 		required="false" 	type="numeric" 									hint="The maximum number of accounts to include in this response." />
		<cfargument name="start_index" 		required="false" 	type="numeric" 									hint="An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" 	required="true"  	type="string" 	default="#getAccess_token()#" 	hint="The access token generated from the successful OAuth authentication process." />
    		<cfset var strURL = getManagementAPIEndpoint() & "accounts/" & arguments.accountId & "/webproperties/" & arguments.webPropertyId & "/customDataSources" />
			<cfset var stuParams = structCopy(arguments) />
			<cfset var strParams = "" />
				<cfset structDelete(stuParams,"accountId") />
				<cfset structDelete(stuParams,"webPropertyId") />
				<cfset structDelete(stuParams,"access_token") />
				<cfset strParams = buildParamString(stuParams) />
				<cfif len(strParams)>
					<cfset strURL = strURL & "?" & strParams />
				</cfif>
		<cfreturn makeRequest(strURL, arguments.access_token) />
	</cffunction>
	
		
	<!--- END Management.customDataSources --->
		
		
	
	<!--- START Management.dailyUploads --->
	<!--- LIST --->
	<!--- GET https://www.googleapis.com/analytics/v3/management/accounts/accountId/webproperties/webPropertyId/customDataSources/customDataSourceId/dailyUploads --->
	<cffunction name="listDailyUploads" access="public" output="false" hint="I return all advanced segments to which the authorized user has access.">
		<cfargument name="accountId" 			required="true" 	type="string" 									hint="Account ID to retrieve web properties for. Can either be a specific account ID or '~all', which refers to all the accounts that user has access to." />
		<cfargument name="customDataSourceId" 	required="true" 	type="string" 									hint="Custom data source Id for daily uploads to retrieve." />
		<cfargument name="end_date" 			required="false" 	type="string" 									hint="End date of the form YYYY-MM-DD." />
		<cfargument name="start_date" 			required="false" 	type="string" 									hint="Start date of the form YYYY-MM-DD." />
		<cfargument name="webPropertyId" 		required="true" 	type="string" 									hint="Web property ID for the daily uploads to retrieve." />
		<cfargument name="max_results" 			required="false" 	type="numeric" 									hint="The maximum number of accounts to include in this response." />
		<cfargument name="start_index" 			required="false" 	type="numeric" 									hint="An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" 		required="true"  	type="string" 	default="#getAccess_token()#" 	hint="The access token generated from the successful OAuth authentication process." />
    		<cfset var strURL = getManagementAPIEndpoint() & "accounts/" & arguments.accountId & "/webproperties/" & arguments.webPropertyId & "/customDataSources" & arguments.customDataSourceId & "/dailyUploads" />
			<cfset var stuParams = structCopy(arguments) />
			<cfset var strParams = "" />
				<cfset structDelete(stuParams,"accountId") />
				<cfset structDelete(stuParams,"customDataSourceId") />
				<cfset structDelete(stuParams,"webPropertyId") />
				<cfset structDelete(stuParams,"access_token") />
				<cfset strParams = buildParamString(stuParams) />
				<cfif len(strParams)>
					<cfset strURL = strURL & "?" & strParams />
				</cfif>
		<cfreturn makeRequest(strURL, arguments.access_token) />
	</cffunction>
	
		
	<!--- POST https://www.googleapis.com/upload/analytics/v3/management/accounts/accountId/webproperties/webPropertyId/customDataSources/customDataSourceId/dailyUploads/date/uploads --->
	
		
	<!--- DELETE https://www.googleapis.com/analytics/v3/management/accounts/accountId/webproperties/webPropertyId/customDataSources/customDataSourceId/dailyUploads/date --->
	
		
	<!--- END Management.dailyUploads --->
		
		
		
	<!--- START Management.experiments --->
	<!--- LIST --->
	<!--- GET https://www.googleapis.com/analytics/v3/management/accounts/accountId/webproperties/webPropertyId/profiles/profileId/experiments --->
	<cffunction name="listExperiments" access="public" output="false" hint="">
		<cfargument name="accountID" 		required="true" 	type="string" 									hint="The analytics account ID." />
		<cfargument name="webPropertyID" 	required="true" 	type="string" 									hint="The analytics web property ID." />
		<cfargument name="profileID" 		required="true" 	type="string" 									hint="The analytics profile ID." />
		<cfargument name="max_results" 		required="false" 	type="numeric" 									hint="The maximum number of experiments to include in this response." />
		<cfargument name="start_index" 		required="false" 	type="numeric" 									hint="An index of the first experiment to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="access_token" 	required="true"		type="string"	default="#getAccess_token()#"	hint="The access token generated from the successful OAuth authentication process." />
			<cfset var strURL = getManagementAPIEndpoint() & "accounts/" & arguments.accountId & "/webproperties/" & arguments.webPropertyId & "/profiles/" & arguments.profileID & "/experiments" />
			<cfset var stuParams = structCopy(arguments) />
			<cfset var strParams = "" />
				<cfset structDelete(stuParams,"accountId") />
				<cfset structDelete(stuParams,"webPropertyId") />
				<cfset structDelete(stuParams,"profileID") />
				<cfset structDelete(stuParams,"access_token") />
				<cfset strParams = buildParamString(stuParams) />
				<cfif len(strParams)>
					<cfset strURL = strURL & "?" & strParams />
				</cfif>
		<cfreturn makeRequest(strURL, arguments.access_token) />
	</cffunction>
	
	<!--- GET --->
	<!--- GET https://www.googleapis.com/analytics/v3/management/accounts/accountId/webproperties/webPropertyId/profiles/profileId/experiments/experimentId --->
	<cffunction name="getExperiment" access="public" output="false" hint="">
		<cfargument name="accountId" 		required="true" 	type="string" 													hint="The analytics account ID." />
		<cfargument name="webPropertyId" 	required="true" 	type="string" 													hint="The analytics web property ID." />
		<cfargument name="profileID" 		required="true" 	type="string" 													hint="The analytics profile ID." />
		<cfargument name="experimentID" 	required="true" 	type="string" 													hint="The analytics experiment ID." />
		<cfargument name="access_token" 	required="true"		type="string"	default="#getAccess_token()#"					hint="The access token generated from the successful OAuth authentication process." />
			<cfset var strURL = getManagementAPIEndpoint() & "accounts/" & arguments.accountId & "/webproperties/" & arguments.webPropertyId & "/profiles/" & arguments.profileID & "/experiments/" & arguments.experimentID />
		<cfreturn makeRequest(strURL, arguments.access_token) />	
	</cffunction>
	
	<!--- INSERT --->
	<!--- POST https://www.googleapis.com/analytics/v3/management/accounts/accountId/webproperties/webPropertyId/profiles/profileId/experiments --->
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
			
			<!---<cfif checkExperimentStatusIsValid(status=arguments.status, method="insert")>
				
				<!--- Now check the variation array. --->
				<cfset stuVariationCheck = checkVariationsAreValid(arguments.variations) />
				<cfif stuVariationCheck.valid>
					
				<cfelse>
					<cfthrow message="#stuVariationCheck.message#" />
				</cfif>
				
			<cfelse>
				not valid
			</cfif>--->
			<cfset var strURL = getManagementAPIEndpoint() & "accounts/" & arguments.accountId & "/webproperties/" & arguments.webPropertyId & "/profiles/" & arguments.profileID & "/experiments" />
	
		<cfreturn makeRequest(strURL,arguments.access_token, "POST") /> 
	</cffunction>

	<!--- END Management.experiments --->
		

	<!--- END Management API Methods --->
		
	<!--- UTILS --->
	
	<cffunction name="makeRequest" access="private" returntype="Struct" hint="I make the actual request to the remote API.">
        <cfargument name="remoteURL" 	type="string" required="true" 					hint="The generated remote URL for the request, including query string params. This does not include the access_token from the OAuth authentication process." />
        <cfargument name="authToken" 	type="string" required="true" 					hint="The access_token from the OAuth authentication process, which will be appended to the query string." />
		<cfargument name="method" 		type="string" required="false" default="GET" 	hint="The method used for the request. Default is GET." />
			<cfset var authSubToken 	= 'Bearer ' & arguments.authToken />
				<cfhttp url="#arguments.remoteURL#" method="#arguments.method#">
		            <cfhttpparam name="Authorization" 	type="header" value="#authSubToken#" />
					<!---<cfhttpparam name="Content-Type"	type="header" value="application/json" />--->
		        </cfhttp>
         <cfreturn deserializeJSON(cfhttp.filecontent) />
    </cffunction>
    
    <cffunction name="clearEmptyParams" access="private" output="false" returntype="Struct" hint="I accept the structure of arguments and remove any empty / nulls values before they are sent to the OAuth processing.">
		<cfargument name="paramStructure" required="true" type="Struct" hint="I am a structure containing the arguments / parameters you wish to filter." />
			<cfset var stuRevised = {} />
				<cfloop collection="#arguments.paramStructure#" item="key">
					<cfif len(arguments.paramStructure[key])>
						<cfset structInsert(stuRevised, lcase(key), arguments.paramStructure[key], true) />
					</cfif>
				</cfloop>
		<cfreturn stuRevised />
	</cffunction>
	
	<cffunction name="buildParamString" access="private" output="false" returntype="String" hint="I loop through a struct to convert to query params for the URL">
		<cfargument name="argScope" required="true" type="struct" hint="I am the struct containing the method params" />
			<cfset var strURLParam 	= '' />
			<cfloop collection="#arguments.argScope#" item="key">
				<cfif len(arguments.argScope[key])>
					<cfif listLen(strURLParam)>
						<cfset strURLParam = strURLParam & '&' />
					</cfif>
					<cfset strURLParam = strURLParam & replaceNoCase(lcase(key),"_","-","all") & '=' & arguments.argScope[key] />
				</cfif>
			</cfloop>
		<cfreturn strURLParam />
	</cffunction>
	
	<cffunction name="checkVariationsAreValid" access="private" output="false" hint="I check the variations array to make sure everything is included before you make your request.">
		<cfargument name="variations" required="true" type="array" hint="The array of structs containing variation data." />
			<cfset var stuResponse 		= {} />
			<cfset var strErrorMessage	= "" />
			<cfset var isValidVariation = true />
			<cfset var arrVariations 	= arguments.variations />
			<cfset var intVarLength 	= arrayLen(arrVariations) />
				<cfif intVarLength LT 2>
					<cfset strErrorMessage = "The variation array must have at least two indexes. ('original' and 'revised version' for example.)" />
					<cfset isValidVariation = false />
				<cfelse>
					<cfloop from="1" to="#intVarLength#" index="variation">
						<cfif !structKeyExists(arrVariations[variation], "URL") OR !structKeyExists(arrVariations[variation], "NAME")>
							<cfset strErrorMessage = "Each variation must have a URL and NAME value" />
							<cfset isValidVariation = false />
						</cfif>
						<cfdump var="#arrVariations[variation]#"><br />	
					</cfloop>
				</cfif>
			<cfset structInsert(stuResponse,"valid",isValidVariation) />
			<cfset structInsert(stuResponse,"message",strErrorMessage) />
		<cfreturn stuResponse />
	</cffunction>
	
	<cffunction name="checkExperimentStatusIsValid" access="private" output="false" hint="I make sure the status value is right.">
		<cfargument name="status" 	required="true" type="string" hint="The status value." />
		<cfargument name="method"	required="true" type="string" hint="The type of method you are performing.. eg INSERT, UPDATE." />
			<cfset var isValidStatus = true />
			<cfset var strStatusList = "DRAFT, READY_TO_RUN, RUNNING, ENDED" />
				<cfswitch expression="#arguments.method#">
					<cfcase value="insert">
						<cfif arguments.status EQ "ENDED">
							<cfset isValidStatus = false />
						</cfif>
					</cfcase>
				</cfswitch>
		<cfreturn isValidStatus />
	</cffunction>
	
	<!--- END UTILS --->
	
</cfcomponent>