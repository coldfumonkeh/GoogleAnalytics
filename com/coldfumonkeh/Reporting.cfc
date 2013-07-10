<cfcomponent output="false" accessors="true" extends="Utils">
	
	<cfproperty name="reportingAPIEndpoint"		type="string" />
	
	<cffunction name="init" output="false" access="package" hint="The constructor method.">
		<cfargument name="reportingAPIEndpoint"	type="string" required="true" hint="The base reporting API URL to which we will make the API requests." />
			<cfset setReportingAPIEndpoint(arguments.reportingAPIEndpoint) />
		<cfreturn this />
	</cffunction>
	
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
	
</cfcomponent>