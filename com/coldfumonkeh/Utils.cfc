<cfcomponent output="false">
	
	<!--- UTILS --->
		
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
	
	<cffunction name="makeRequest" access="private" returntype="Struct" hint="I make the actual request to the remote API.">
        <cfargument name="remoteURL" 	type="string" required="true" 					hint="The generated remote URL for the request, including query string params. This does not include the access_token from the OAuth authentication process." />
        <cfargument name="authToken" 	type="string" required="true" 					hint="The access_token from the OAuth authentication process, which will be appended to the query string." />
		<cfargument name="method" 		type="string" required="false" default="GET" 	hint="The method used for the request. Default is GET." />
			<cfset var authSubToken 	= 'Bearer ' & arguments.authToken />
			<cfif listFirst(server.coldfusion.productversion) EQ "9">
				<cfhttp url="#arguments.remoteURL#" method="#arguments.method#">
					<cfhttpparam name="Authorization" 	type="header" value="#authSubToken#" />
				</cfhttp>
				<cfreturn deserializeJSON(cfhttp.filecontent).toString('UTF-8') />
			<cfelse>
				<cfhttp url="#arguments.remoteURL#" method="#arguments.method#" charset="UTF-8">
					<cfhttpparam name="Authorization" 	type="header" value="#authSubToken#" />
				</cfhttp>
				<cfreturn deserializeJSON(cfhttp.filecontent) />
			</cfif>
    </cffunction>
    
    <cffunction name="clearEmptyParams" access="private" output="false" returntype="Struct" hint="I accept the structure of arguments and remove any empty / nulls values before they are sent to the OAuth processing.">
		<cfargument name="paramStructure" required="true" type="Struct" hint="I am a structure containing the arguments / parameters you wish to filter." />
			<cfset var stuRevised = {} />
				<cfloop collection="#arguments.paramStructure#" item="key">
					<cfif structKeyExists(arguments.paramStructure, key)>
						<cfset structInsert(stuRevised, lcase(key), arguments.paramStructure[key], true) />
					</cfif>
				</cfloop>
		<cfreturn stuRevised />
	</cffunction>

	<cffunction name="buildParamString" access="private" output="false" returntype="String" hint="I loop through a struct to convert to query params for the URL">
		<cfargument name="argScope" required="true" type="struct" hint="I am the struct containing the method params" />
			<cfset var strURLParam 	= '' />

			<cfloop collection="#arguments.argScope#" item="key">
				<cfif structKeyExists(arguments.argScope, key)>
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