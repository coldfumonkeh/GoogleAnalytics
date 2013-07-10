# Google Analytics #

A ColdFusion wrapper to interact with the Google Analytics Management and Core Reporting APIs, complete with OAuth2 authentication protocols.


# Getting Started #

To integrate the Google Analytics Management / Reporting data into your ColdFusion application, you will first need to register your app in the [Google API Console](https://code.google.com/apis/console/b/0/)

Once complete, make a note of your client id and client secret values, as well as the callback URL you specified. These values will need to be entered into the **init()** method of the component.

## Instantiation ##

Firstly, set up the **init()** constructor method. This _could be_ in your Application scope for persistence, as in the following example:

	<cfset application.objGA = new com.coldfumonkeh.GoogleAnalytics(
					client_id		=	'< your client id value >',
					client_secret	=	'< your client secret value >',
					redirect_uri	=	'http://127.0.0.1:8500/googleanalytics/index.cfm', // the redirect URI
					readonly		=	true, // defaults to true. false will enable write access and set the scope accordingly.
					state			=	'',
					access_type		=	'online', // online or offline
					approval_prompt	=	'force'
				) />

Full details on the values within the **init()** method can be found in the documentation section "[Forming the URL](https://developers.google.com/accounts/docs/OAuth2WebServer)"

## Logging In ##


To access the data from the API, the user will have to authenticate by signing in to their Google Analytics account. This will also prompt them to grant access (should they wish to) for your application to read their profile data for them. This is the first step in the OAuth2 process.

To do so, you need to generate a specific URL, which the component will do for you using the **getLoginURL()** method:

	<cfoutput><a href="#application.objGA.getLoginURL()#">Login and Authenticate</a></cfoutput>

The resulting URL will look something like this:

	https://accounts.google.com/o/oauth2/auth?
		scope=https://www.googleapis.com/auth/analytics.readonly
		&redirect_uri=http://127.0.0.1:8500/googleanalytics/index.cfm
		&response_type=code
		&client_id=<your client id here>
		&access_type=online


Assuming a successful authentication, the OAuth process will relocate to the callback URI defined in your app settings with an appended query string parameter, **code**.

Exchange this temporary code for an access token, which you can do using the **getAccessToken()** method from this component, like so:

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
			<p>Failed authentication.</p>
		</cfif>
		
	</cfif>

Once the user is logged in using the access token details, you have a limit for the life span of that token, which can be seen in the returned **expires_in_raw** and **expires_in** values from the **authResponse** value, returned from the method.

### Revoking Access ###

A user can revoke access to you application by logging into their [Google acount management screen](https://accounts.google.com/b/0/IssuedAuthSubTokens).
This component offers a simple method to allow them to revoke access easily directly within your application, using the **revokeAccess()** method.

In this example, we will provide the logged in user a link to a new page:

	<!---
		If the SESSION key exists, we seem to have access to the API.
	--->
	<cfif structKeyExists(session, "google_api_auth")>
		
		<a href="revoke.cfm">Revoke API Access</a>

	</cfif>

When landing on that page, the **revokeAccess()** method is called before they are redirected back to the index page:

	<!--- Revoke access --->
	<cfset revokeAccess = application.objGA.revokeAccess() />
	<cflocation url="index.cfm?reinit=1" addtoken="false" />


## I'm logged in. Now what? ##

Now you can call methods to access your analytics data.

# Core Reporting API #

Firstly, get the list of available profiles within your analytics account using the **getProfiles()** method:

	<cfset stuProfiles = application.objGA.getProfiles() />

This returns a struct of arrays, each item in the array being a profile (site or app) set up within Google Analytics.

The main method available to use for all requests to the Core Reporting API is the generic **queryAnalytics()** method.
This method accepts all parameters from the remote API, and allows you to query on a specific profile:

	<cfset stuData = application.objGA.queryAnalytics(
							profileID		=	"< your profile ID >",
							start_date		=	"2009-05-20", 
							end_date		=	"2012-12-12",
						) />

The default dates (if not provided in the method call itself) are for the previous week (Now() -7)

This method is highly configurable (it needs to be) to allow you to query for specific metrics and dimensions to get the relevant informatio you 
require in your report.

Documentation for available dimensions and metrics can be found here [https://developers.google.com/analytics/devguides/reporting/core/dimsmets](https://developers.google.com/analytics/devguides/reporting/core/dimsmets)


## Specific Methods ##

The component contains a few methods that obtain specific sets of information based upon the provided metrics and dimensions.

**getProfileData()** will return a high-level snapshot of common analytical data for the provided profile ID, returning a struct of information containing:

* visit snapshot
* visitor loyalty
* visit chart
* country chart
* top pages

To get this information, simply run the method as in the example below:

	<cfset stuProfileData = application.objGA.getProfileData(
					profileID		=	"< your profile ID >", 
					start_date		=	"2009-05-20", 
					end_date		=	"2013-01-09"
				) />


**getPageVistsForURI()** lets you obtain page visit information for a specific page URI within the provided date range. Simply pass in the URI value:

	<cfset application.objGA.getPageVistsForURI(
					profileID		=	"< your profile ID >", 
					start_date		=	"2009-05-20", 
					end_date		=	"2012-12-12", 
					uri				=	"your-page-or-blog-uri"
				) />


# I want to keep my user logged in. How? #

If you want to persist the access to the authenticated and approved account, you can do so easily using this component.

You will need to amend the **init()** method to change the **access_type** value to **offline**.
By doing so, when you request the access_token using the **getAccessToken()** method, you will also receive a **refresh_token** value.

The refresh_token can be stored somewhere persistent (database, text file) and can be used to obtain a new access_token on behalf of the user without them having to authenticate and approve again.

The component will also set these values into the access_token and refresh_token properties within the object itself.

You can regenerate a new token by calling the **refreshToken()** method. This will take the refresh_token value from the object property and generate a new access_token, storing it back into the object as well as returning the structure out to the code for you to insert into the SESSION scope (if you wish to).

If you have the refresh and access token details, you can also set these directly into the object like so:

	<cfset application.objGA = new com.coldfumonkeh.GoogleAnalytics(
					client_id		=	'< your client id value >',
					client_secret	=	'< your client secret value >',
					redirect_uri	=	'http://127.0.0.1:8500/googleanalytics/index.cfm', // the redirect URI
					readonly		=	true,
					state			=	'',
					access_type		=	'offline',
					approval_prompt	=	'force'
				) />

	<cfset application.objGA.setRefresh_token('< your refresh token value >') />
	<cfset application.objGA.setAccess_token('< your access token value >') />


# Official References #

To find out more about the Core Reporting API (v3), check out the [official documentation](https://developers.google.com/analytics/devguides/reporting/core/v3/reference) from Google.

# Acknowledgements & Thanks #

This starting point for this component was based upon the open source release from [Jen](https://github.com/jensbits/Google-Analytics-Data-Export-API-with-ColdFusion). Original blog post from Jen about her project available [here](http://www.jensbits.com/2012/04/05/google-analytics-reporting-api-using-oauth-2-with-coldfusion/)

