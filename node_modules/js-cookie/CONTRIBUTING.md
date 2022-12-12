## Issues

- Report issues or feature requests on [GitHub Issues](https://github.com/js-cookie/js-cookie/issues).
- If reporting a bug, please add a [simplified example](http://sscce.org/).

## Pull requests
- Create a new topic branch for every separate change you make.
- Create a test case if you are fixing a bug or implementing an important feature.
- Make sure the build runs successfully.

## Development

### Tools
We use the following tools for development:

- [Qunit](http://qunitjs.com/) for tests.
- [NodeJS](http://nodejs.org/download/) required to run grunt.
- [Grunt](http://gruntjs.com/getting-started) for task management.

### Getting started 
Install [NodeJS](http://nodejs.org/).  
Install globally grunt-cli using the following command:

    $ npm install -g grunt-cli

Browse to the project root directory and install the dev dependencies:

    $ npm install -d

To execute the build and tests run the following command in the root of the project:

    $ grunt

You should see a green message in the console:

    Done, without errors.

### Tests
You can also run the tests in the browser.  
Start a test server from the project root:

    $ grunt connect:tests

This will automatically open the test suite at http://127.0.0.1:10000 in the default browser, with livereload enabled.

_Note: we recommend cleaning all the browser cookies before running the tests, that can avoid false positive failures._

### Automatic build
You can build automatically after a file change using the following command:

    $ grunt watch

## Integration with server-side

js-cookie allows integrating the encoding test suite with solutions written in other server-side languages. To integrate successfully, the server-side solution need to execute the `test/encoding.html` file in it's integration testing routine with a web automation tool, like [Selenium](http://www.seleniumhq.org/). js-cookie test suite exposes an API to make this happen.

### ?integration_baseurl

Specify the base url to pass the cookies into the server through a query string. If `integration_baseurl` query is not present, then js-cookie will assume there's no server.

### window.global_test_results

After the test suite has finished, js-cookie exposes the global `window.global_test_results` property containing an Object Literal that represents the [QUnit's details](http://api.qunitjs.com/QUnit.done/). js-cookie also adds an additional property representing an Array containing the tests data.

### Handling requests

When js-cookie encoding tests are executed, it will request a url in the server through an iframe representing each test being run. js-cookie expects the server to handle the input and return the proper `Set-Cookie` headers in the response. js-cookie will then read the response and verify if the encoding is consistent with js-cookie default encoding mechanism

js-cookie will send some requests to the server from the baseurl in the format `/encoding?name=<cookie>`, where `<cookie>` represents the cookie-name to be read from the request.

The server should handle those requests, internally parsing the cookie from the request and writing it again. It must set an `application/json` content type containing an object literal in the content body with `name` and `value` keys, each representing the cookie-name and cookie-value decoded by the server-side implementation.

If the server fails to respond with this specification in any request, the related QUnit test will fail. This is to make sure the server-side implementation will always be in sync with js-cookie encoding tests for maximum compatibility.

### Projects using it

This hook is being used in the following projects:

* [Java Cookie](https://github.com/js-cookie/java-cookie).
