<cfcomponent output="false" accessors="true" extends="Utils">
	
	<cfproperty name="managementAPIEndpoint"	type="string" />
	
	<cffunction name="init" output="false" access="package" hint="The constructor method.">
		<cfargument name="managementAPIEndpoint" type="string" required="false" default="https://www.googleapis.com/analytics/v3/management/" 	hint="The base management API URL to which we will make the API requests." />
			<cfset setManagementAPIEndpoint(arguments.managementAPIEndpoint) />
		<cfreturn this />
	</cffunction>
	
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
	
</cfcomponent>