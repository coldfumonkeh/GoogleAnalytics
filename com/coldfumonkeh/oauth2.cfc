<cfcomponent displayname="Oauth2" accessors="true" output="false">

<cfproperty name="client_id" 		type="string" />
<cfproperty name="client_secret" 	type="string" />
<cfproperty name="redirect_uri" 	type="string" />
<cfproperty name="scope" 			type="string" />
<cfproperty name="state" 			type="string" />
<cfproperty name="access_type"		type="string" />
<cfproperty name="approval_prompt"	type="string" />

<!--- Auth details from the authentication --->
<cfproperty name="access_token"		type="string" default="" />
<cfproperty name="refresh_token"	type="string" default="" />

<!--- token handling --->

<!--- token_storage can be 'session' or 'application' --->
<cfproperty name="token_storage"	type="string" /> 

<cffunction name="setToken_storage" access="private" output="false">
	<cfargument name="token_storage" type="string" required="true">
	
	<!--- enforce constraint on token_storage value --->
	<cfif listFindNoCase('application,session', arguments.token_storage, ",") EQ 0>
		<cfthrow message="token_storage value must be 'session' or 'application'">
	</cfif>

	<cfset variables.token_storage = arguments.token_storage>
</cffunction>

<cffunction name="createTokenStruct" access="private" output="false" hint="create a token structure in the scope specified by property token_storage">
	<!--- generate the structure name from the client_id so we are not likely to have a name conflict --->
	<cfif NOT isDefined('#getToken_storage()#.oauth2#getClient_id()#')>
		<cfif getToken_storage() EQ 'session'>
			<cfset session['oauth2#getClient_id()#'] = structNew()>
		<cfelse>
			<cfset application['oauth2#getClient_id()#'] = structNew()>		
		</cfif>
				
		<cfset getTokenStruct().access_token = "">		
		<cfset getTokenStruct().refresh_token = "">		
	</cfif>
</cffunction>

<cffunction name="getTokenStruct" access="private" returntype="struct" output="false" hint="returns the oauth token structure">
	<!--- first make sure the token structure exists --->
	<cfset createTokenStruct()>
	
	<!--- return the token structure --->
	<cfif getToken_storage() EQ 'session'>
		<cfreturn session['oauth2#getClient_id()#']>
	<cfelse>
		<cfreturn application['oauth2#getClient_id()#']>
	</cfif>
</cffunction>

<cffunction name="getAccess_token" access="public" returntype="string" output="false" hint="getter for oauth access_token">
	<cfreturn getTokenStruct().access_token>
</cffunction>

<cffunction name="setAccess_token" access="private" output="false" hint="setter for oauth access_token">
	<cfargument name="access_token" type="string" required="true">
	<cfset getTokenStruct().access_token = arguments.access_token>
</cffunction>

<cffunction name="getRefresh_token" access="public" returntype="string" output="false" hint="getter for oauth refresh_token">
	<cfreturn getTokenStruct().access_token>
</cffunction>

<cffunction name="setRefresh_token" access="private" output="false" hint="setter for oauth refresh_token">
	<cfargument name="refresh_token" type="string" required="true">
	<cfset getTokenStruct().refresh_token = arguments.refresh_token>
</cffunction>

<!--- end of token handling --->


<cffunction name="init" access="public" output="false" hint="The constructor method.">
	<cfargument name="client_id" 		type="string" required="true"					hint="Indicates the client that is making the request. The value passed in this parameter must exactly match the value shown in the APIs Console." />
	<cfargument name="client_secret" 	type="string" required="true"					hint="The secret key associated with the client." />
	<cfargument name="redirect_uri" 	type="string" required="true"					hint="Determines where the response is sent. The value of this parameter must exactly match one of the values registered in the APIs Console (including the http or https schemes, case, and trailing '/')." />
	<cfargument name="scope" 			type="string" required="true"					hint="Indicates the Google API access your application is requesting. The values passed in this parameter inform the consent page shown to the user. There is an inverse relationship between the number of permissions requested and the likelihood of obtaining user consent." />
	<cfargument name="state" 			type="string" required="true"					hint="Indicates any state which may be useful to your application upon receipt of the response. The Google Authorization Server roundtrips this parameter, so your application receives the same value it sent. Possible uses include redirecting the user to the correct resource in your site, nonces, and cross-site-request-forgery mitigations." />
	<cfargument name="access_type" 		type="string" required="false" default="online" hint="ONLINE or OFFLINE. Indicates if your application needs to access a Google API when the user is not present at the browser. This parameter defaults to online. If your application needs to refresh access tokens when the user is not present at the browser, then use offline. This will result in your application obtaining a refresh token the first time your application exchanges an authorization code for a user." />
	<cfargument name="approval_prompt"	type="string" required="false" default="auto" 	hint="AUTO or FORCE. Indicates if the user should be re-prompted for consent. The default is auto, so a given user should only see the consent page for a given set of scopes the first time through the sequence. If the value is force, then the user sees a consent page even if they have previously given consent to your application for a given set of scopes." />
	<cfargument name="baseAuthEndpoint"	type="string" required="false" default="https://accounts.google.com/o/oauth2/" 				hint="The base URL to which we will make the OAuth requests." />
	<cfargument name="baseAPIEndpoint"	type="string" required="false" default="" 	hint="The base URL to which we will make the API requests." />
	<cfargument name="token_storage" 	type="string" required="true" default="session"	hint="scope to store the tokens in (session, application)">
	
	<cfset setClient_id(arguments.client_id) />
	<cfset setClient_secret(arguments.client_secret) />
	<cfset setRedirect_uri(arguments.redirect_uri) />
	<cfset setScope(arguments.scope) />
	<cfset setState(arguments.state) />
	<cfset setAccess_type(arguments.access_type) />
	<cfset setBaseAuthEndpoint(arguments.baseAuthEndpoint) />
	<cfset setBaseAPIEndpoint(arguments.baseAPIEndpoint) />

	<cfset setToken_storage(arguments.token_storage)>
	<cfset createTokenStruct()>

	<cfreturn this />
</cffunction>

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

<cffunction name="makeRequest" access="private" returntype="Struct" hint="I make the actual request to the remote API.">
	<cfargument name="remoteURL" 	type="string" required="yes" hint="The generated remote URL for the request, including query string params. This does not include the access_token from the OAuth authentication process." />
	
	<cfset var authSubToken 	= 'Bearer ' & getAccess_token() />
	<cfhttp url="#arguments.remoteURL#" method="get">
		<cfhttpparam name="Authorization" type="header" value="#authSubToken#">
	</cfhttp>
  	
	<cfreturn deserializeJSON(cfhttp.filecontent) />
</cffunction>

</cfcomponent>