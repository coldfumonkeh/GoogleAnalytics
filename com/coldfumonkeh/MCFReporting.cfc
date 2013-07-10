<cfcomponent output="false" accessors="true" extends="Utils">
	
	<cfproperty name="mcfreportingAPIEndpoint" type="string" />
	
	<cffunction name="init" output="false" access="package" hint="The constructor method.">
		<cfargument name="mcfreportingAPIEndpoint"	type="string" required="true" hint="The base multi-channel funnels reporting API URL to which we will make the API requests." />
			<cfset setMCFReportingAPIEndpoint(arguments.mcfreportingAPIEndpoint) />
		<cfreturn this />
	</cffunction>
	
	<!---
		ids	string	yes	The unique table ID of the form ga:XXXX, where XXXX is the Analytics profile ID for which the query will retrieve the data.
start-date	string	yes	The first date of the date range for which you are requesting the data.
end-date	string	yes	The last date of the date range for which you are requesting the data.
metrics	string	yes	A list of comma-separated metrics, such as mcf:totalConversions,mcf:totalConversionValue. A valid query must specify at least one metric.
dimensions	string	no	A list of comma-separated dimensions for your Multi-Channel Funnels report, such as mcf:source,mcf:keyword.
sort	string	no	 A list of comma-separated dimensions and metrics indicating the sorting order and sorting direction for the returned data.
filters	string	no	Dimension or metric filters that restrict the data returned for your request.
start-index	integer	no	The first row of data to retrieve, starting at 1. Use this parameter as a pagination mechanism along with the max-results parameter.
max-results	integer	no	The maximum number of rows to include in the response.	
	--->
	
	<cffunction name="queryMCFAnalytics" access="public" output="false" returntype="Struct" hint="I make a generic request to the Google Analytics API, based upon the parameters you provide me.">
		<cfargument name="profileID" 	required="true" 	type="string" 													hint="The unique table ID of the form ga:XXXX, where XXXX is the Analytics profile ID for which the query will retrieve the data." />
		<cfargument name="start_date" 	required="true" 	type="string"	default="#DateFormat(Now()-7, "yyyy-mm-dd")#" 	hint="The first date of the date range for which you are requesting the data." />
		<cfargument name="end_date" 	required="true" 	type="string" 	default="#DateFormat(Now(), "yyyy-mm-dd")#"		hint="The last date of the date range for which you are requesting the data." />
		<cfargument name="metrics" 		required="true" 	type="string" 	default="ga:visits,ga:bounces"					hint="A list of comma-separated metrics, such as ga:visits,ga:bounces." />
		<cfargument name="dimensions" 	required="false"	type="string"													hint="A list of comma-separated dimensions for your Analytics data, such as ga:browser,ga:city." />
		<cfargument name="sort" 		required="false" 	type="string" 													hint="A list of comma-separated dimensions and metrics indicating the sorting order and sorting direction for the returned data." />
		<cfargument name="filters" 		required="false" 	type="string" 													hint="Dimension or metric filters that restrict the data returned for your request." />
		<cfargument name="start_index" 	required="false" 	type="string" 													hint="The first row of data to retrieve, starting at 1. Use this parameter as a pagination mechanism along with the max-results parameter." />
		<cfargument name="max_results" 	required="false" 	type="string" 													hint="The maximum number of rows to include in the response." />
		<cfargument name="access_token" required="true"		type="string"	default="#getAccess_token()#"					hint="The access token generated from the successful OAuth authentication process." />
			<cfset var strURL 		= "" />
			<cfset var strParams 	= "" />
			<cfset var stuTemp 		= structCopy(arguments) />
				<!--- Remove values we dont want in the URL query string --->
				<cfset structDelete(stuTemp,"profileID") />
				<cfset structDelete(stuTemp,"access_token") />
				<!--- Build the params and URL --->
				<cfset strParams = buildParamString(clearEmptyParams(stuTemp)) />
				<cfset strURL = getMCFReportingAPIEndpoint() & "?ids=ga:" & arguments.profileID & "&" & strParams />
		<cfreturn makeRequest(remoteURL = strURL, authToken = arguments.access_token) />
	</cffunction>
	
</cfcomponent>