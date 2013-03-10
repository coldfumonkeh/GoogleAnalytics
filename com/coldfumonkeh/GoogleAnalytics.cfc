<!---
Name: GoogleAnalytics.cfc
Author: Matt Gifford
Date: 9th January 2013
Purpose: 
	This component interacts with the Google Analytics API to retrieve data for analysis and display.
	The requests require authentication through the OAuth2 protocol, also handled by this component.
--->
<cfcomponent output="false" extends="oauth2" accessors="true">
	
<!--- Google API Details --->
<cfproperty name="baseAuthEndpoint"	type="string" />
<cfproperty name="baseAPIEndpoint"	type="string" />
	
<cffunction name="init" access="public" output="false" hint="The constructor method.">
	<cfset arguments.baseAPIEndpoint = "https://www.googleapis.com/analytics/v3/data/ga">
	<cfset arguments.scope = 'https://www.googleapis.com/auth/analytics.readonly'>

	<cfset super.init(argumentCollection: arguments)>
	
	<cfreturn this />
</cffunction>
		
<!--- START API Methods --->
		
<cffunction name="getProfiles" access="public" output="false" returntype="Struct" hint="I return an array of available profiles for the authenticated user.">
  	<cfreturn makeRequest("https://www.googleapis.com/analytics/v3/management/accounts/~all/webproperties/~all/profiles") /> 
</cffunction>
    
<cffunction name="getProfileData" access="public" output="false" returntype="Struct" hint="I return data for the selected profile.">
	<cfargument name="profileID" 	required="true" type="string" 								hint="The analytics profile ID." />
	<cfargument name="start_date" 	required="true" type="string" 								hint="The first date of the date range for which you are requesting the data." />
	<cfargument name="end_date" 	required="true" type="string" 								hint="The last date of the date range for which you are requesting the data." />
		
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
	
	<cfset var strURL 		= "" />
	<cfset var strParams 	= "" />
	<cfset var stuTemp 		= structCopy(arguments) />
	<!--- Remove values we dont want in the URL query string --->
	<cfset structDelete(stuTemp,"profileID") />
	<cfset structDelete(stuTemp,"access_token") />
	<!--- Build the params and URL --->
	<cfset strParams = buildParamString(clearEmptyParams(stuTemp)) />
	<cfset strURL = getBaseAPIEndpoint() & "?ids=ga:" & arguments.profileID & "&" & strParams />
	
	<cfreturn makeRequest(remoteURL = strURL) />
</cffunction>
	<!--- END API Methods --->
	
<!--- UTILS --->
    
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
	
<!--- END UTILS --->
	
</cfcomponent>