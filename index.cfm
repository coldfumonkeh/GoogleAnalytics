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
		<cflocation url="index.cfm" addtoken="false" />
	<cfelse>
		<!---
			Failure to authenticate.
			Handle this however you want to.
		--->
		failed authentication.
	</cfif>
	
</cfif>

<cfdump var="#session#">		
		
<!---
	If the SESSION key exists, we seem to have access to the API.
--->
<cfif structKeyExists(session, "google_api_auth")>
	
	<a href="revoke.cfm">Revoke API Access</a>
	
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
	
	<cfset stuData = application.objGA.getProfiles() />
	
	<cfdump var="#stuData#">
	
<cfelse>

<!---
	We are not logged in or authenticated.
	Let's do that now so that the user can access the Analytics data.
--->
<cfoutput><a href="#application.objGA.getLoginURL()#">Login and Authenticate</a></cfoutput>

</cfif>