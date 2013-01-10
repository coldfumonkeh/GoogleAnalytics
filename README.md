Google Analytics
================

A ColdFusion wrapper to interact with the Google Analytics Core Reporting API and OAuth2 authentication protocols.


Getting Started
===============

To integrate the Google Analytics Core Reporting data into your ColdFusion application, you will first need to register your app in the "Google API Console":https://code.google.com/apis/console/b/0/

Once complete, make a note of your client id and client secret values, as well as the callback URL you specified. These values will be entered into the **init()** method of the component.

Instantiation
-------------

Firstly, set up the **init()** constructor method. This _could be_ in your Application scope for persistence.

	<cfset application.objGA = new com.coldfumonkeh.GoogleAnalytics(
					client_id		=	'< your client id value >',
					client_secret	=	'< your client secret value >',
					redirect_uri	=	'http://127.0.0.1:8500/googleanalytics/index.cfm', // the redirect URI
					scope			=	'https://www.googleapis.com/auth/analytics.readonly',
					state			=	'',
					access_type		=	'online',
					approval_prompt	=	'force'
				) />



Logging In
----------

To access the data from the API, the user will have to authenticate by signing in to their Google account. This will also prompt them to grant access (should they wish to) for your application to read their profile data for them. This is the first step in the OAuth2 process.

To do so, you need to generate a specific URL, which the component will do for you using the **getLoginURL()** method:

	<cfoutput><a href="#application.objGA.getLoginURL()#">Login and Authenticate</a></cfoutput>

The resulting URL will look something like this:

	https://accounts.google.com/o/oauth2/auth?scope=https://www.googleapis.com/auth/analytics.readonly&redirect_uri=http://127.0.0.1:8500/googleanalytics/index.cfm&response_type=code&client_id=<your client id here>&access_type=online


Official References
===================

To find out more about the Core Reporting API (v3), check out the "official documentation":https://developers.google.com/analytics/devguides/reporting/core/v3/reference from Google.