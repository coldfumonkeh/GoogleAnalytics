<cfcomponent displayname="MyComponentTest"  extends="mxunit.framework.TestCase">
	
	<!--- This will run once after initialization and before setUp(). --->
    <cffunction name="beforeTests" returntype="void" access="public" hint="Put things here that you want to run before all tests.">
		<cfset variables.params = {
			client_id		=	'772265743439-58s3t34rhj9boqfrqscka0q525fg8pdc.apps.googleusercontent.com',
			client_secret	=	'oPOIFjXdr7KcSdwLMWhvJQyM',
			redirect_uri	=	'http://127.0.0.1:8500/googleanalytics/index.cfm',
			readonly		=	false,
			state			=	'',
			access_type		=	'offline',
			approval_prompt	=	'force'
		} />
		<cfset variables.refreshToken 	= "1/bk_imqDTVpELFWHvyRcqHRe-9Y2I83Pt25lymozGf0M" />
		<cfset variables.accessToken	= "ya29.AHES6ZTwGq_nIMqiVsUQWmEgQtvBgA7ajPMz4XZ6H9-EPFc" />
    </cffunction>
	
	<!--- This will run before every single test in this test case. --->
    <cffunction name="setUp" returntype="void" access="public" hint="Put things here that you want to run before each test.">
        <cfset objGA = 
				createObject(
					"component",
					"googleanalytics.com.coldfumonkeh.GoogleAnalytics"
				).init(
					argumentCollection=variables.params
				) />
		<cfset objGA.setRefresh_token(variables.refreshToken) />
		<cfset objGA.setAccess_token(variables.accessToken) />
    </cffunction>

    <!--- This will run after every single test in this test case. --->
    <cffunction name="tearDown" returntype="void" access="public" hint="Put things here that you want to run after each test.">

    </cffunction>

	

    <!--- this will run once after all tests have been run --->

    <cffunction name="afterTests" returntype="void" access="public" hint="Put things here that you want to run after all tests.">

    </cffunction>

	<!--- Initial assertion tests (object and properties values) --->
	<cffunction name="Check_Google_Analytics_Object_Is_Valid_Object" access="public" returntype="void">
		<cfset assertTrue(isObject(objGA)) />
	</cffunction>
	
	<cffunction name="Check_Read_Only_Scope_Is_Correct" access="public" returntype="void">
		<cfset objGA.manageScope(true)>
		<cfset assertEquals("https://www.googleapis.com/auth/analytics.readonly", objGA.getScope()) />
	</cffunction>
	
	<cffunction name="Check_Read_Write_Scope_Is_Correct" access="public" returntype="void">
		<cfset assertEquals("https://www.googleapis.com/auth/analytics", objGA.getsCope()) />
	</cffunction>

	<cffunction name="Check_Object_Is_In_Offline_Mode" returntype="void" access="public">
		<cfset assertEquals("offline", objGA.getAccess_type()) />
	</cffunction>
	
	<cffunction name="Check_Object_Is_In_Online_Mode" returntype="void" access="public">
		<cfset objGA.setAccess_type("online") />
		<cfset assertEquals("online", objGA.getAccess_type()) />
	</cffunction>
	
	<cffunction name="Check_Stored_Access_Token_Is_A_Match">
		<cfset assertEquals(variables.accessToken, objGA.getAccess_token()) />
	</cffunction>
	
	<cffunction name="Check_Stored_Refresh_Token_Is_A_Match">
		<cfset assertEquals(variables.refreshToken, objGA.getRefresh_token()) />
	</cffunction>
	
	<!--- Request / Response API tests --->
	<cffunction name="Check_Account_List_Returns_Data" access="public">
		<cfset response = objGA.listAccounts() />
		<cfset debug(response) />
		<cfset assertTrue(isStruct(response)) />
		<cfset assertTrue(structKeyExists(response, "kind")) />
		<cfset assertEquals("analytics##accounts", response.kind) />
	</cffunction>
	
	<cffunction name="Check_Management_Is_Valid_Object">
		<cfset assertTrue(isObject(objGA.getManagement())) />
		<cfset debug(objGA.getManagement()) />
	</cffunction>
	
	<cffunction name="Check_Reporting_Is_Valid_Object">
		<cfset assertTrue(isObject(objGA.getReporting())) />
		<cfset debug(objGA.getReporting()) />
	</cffunction>

</cfcomponent>