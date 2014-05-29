<cfif structKeyExists(URL, 'code')>
	<!---
		We have the code from the authentication, 
		so let's obtain the access token.
	--->
	<cfset authResponse = application.objGA.getAccessToken(code = URL.code) />
	<cfif authResponse.success>
		<!---
			Store the generated auth response in the SESSION scope.
			We'll use this to detect if we are "logged in" to the API.
		--->
		<cfset structInsert(session, "google_api_auth", authResponse) />
		<cflocation url="index.cfm?accounts" addtoken="false" />
	<cfelse>
		<!---
			Failure to authenticate.
			Handle this however you want to.
		--->
		failed authentication.
	</cfif>
	
</cfif>
<!---
	If the SESSION key exists, we seem to have access to the API.
--->
<cfif structKeyExists(session, "google_api_auth")>
	
	<a href="revoke.cfm">Revoke API Access</a>
	
	<a href="index.cfm?reinit=true">Reload</a>
	
	<!--- 
		check if we're ready to select an account 
	--->
	<cfif structKeyExists(URL, 'accounts')>
		
		<!---
			we are, get the list of accounts
		--->
		<cfset stuData = application.objGA.listAccounts() />
		<!---
			present the accounts to the user to select from
		--->
		<h3>Select Account:</h3>
		<cfloop from="1" to="#ArrayLen(stuData.items)#" index="iX">
			<cfoutput><p><a href="#CGI.SCRIPT_NAME#?properties=&amp;accountId=#stuData.items[i].id#">#stuData.items[i].name#</a></p></cfoutput>
		</cfloop>

	<!--- 
		otherwise, check if we're ready to select a web property 
	--->
	<cfelseif structKeyExists(URL, 'properties')>
		
		<!---
			we are, get the list of web properties from the selected account
		--->
		<cfset stuData = application.objGA.listWebProperties(accountId = URL.accountId) />
		<!---
			present the properties to the user to select from
		--->
		<h3>Select Web Property:</h3>
		<cfloop from="1" to="#ArrayLen(stuData.items)#" index="iX">
			<cfoutput><p><a href="#CGI.SCRIPT_NAME#?profiles=&amp;accountId=#URL.accountId#&amp;propertyId=#stuData.items[i].id#">#stuData.items[i].name#</a></p></cfoutput>
		</cfloop>

	<!--- 
		otherwise, check if we're ready to select a profile 
	--->
	<cfelseif structKeyExists(URL, 'profiles')>
		
		<!---
			we are, get the list of profiles from the selected account and web property
		--->
		<cfset stuData = application.objGA.listProfiles(accountId = URL.accountId, webPropertyId = URL.propertyId) />
		<!---
			present the profiles to the user to select from
		--->
		<h3>Select Profile:</h3>
		<cfloop from="1" to="#ArrayLen(stuData.items)#" index="iX">
			<cfoutput><p><a href="#CGI.SCRIPT_NAME#?analytics=&amp;profileId=#stuData.items[i].id#">#stuData.items[i].name#</a></p></cfoutput>
		</cfloop>

	<!--- 
		otherwise, check if we're ready to gather analytics 
	--->
	<cfelseif structKeyExists(URL, 'analytics')>
		
		<!---
			we are, get the list of profiles from the selected account and web property
		--->
		<cfset stuData = application.objGA.queryAnalytics(profileId = URL.profileId) />
		<!---
			dump the analytics data
		--->
		<cfdump var="#stuData#" label="Analytics Data" />


	</cfif>

	<!---
		<cfdump var="#application.objGA#">
	--->	
	<!---
		<cfset stuData = application.objGA.queryAnalytics(
					profileID		=	"< your profile ID >",
					prettyPrint		=	"true"
				) />
	--->
	<!---
		<cfset stuData = application.objGA.getPageVistsForURI(
					profileID		=	"< your profile ID >", 
					start_date		=	"2009-05-20", 
					end_date		=	"2012-12-12", 
					uri				=	"our-page-or-blog-uri"
				) />
	--->
	<!---
		<cfset stuData = application.objGA.getProfileData(
					profileID		=	"< your profile ID >", 
					start_date		=	"2009-05-20", 
					end_date		=	"2013-01-09"
				) />
	--->
	
	<!--- <cfdump var="#stuData#"> --->
	
<cfelse>

<!---
	We are not logged in or authenticated.
	Let's do that now so that the user can access the Analytics data.
--->
<cfoutput><a href="#application.objGA.getLoginURL()#">Login and Authenticate</a></cfoutput>

</cfif>