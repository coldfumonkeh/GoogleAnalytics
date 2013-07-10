<cfscript>
	testSuite = createObject("component","mxunit.framework.TestSuite").TestSuite();
	testSuite.addAll("googleanalytics.tests.GA_test");
	results = testSuite.run();
	//Now print the results. Simple!
	writeOutput(results.getResultsOutput('html')); //See next section for other output formats
</cfscript>