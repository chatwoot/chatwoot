# Contributing

## Contributor License Agreement

In order to contribute, you must accept the [contributor license agreement](https://cla-assistant.io/dequelabs/axe-core) (CLA). Acceptance of this agreement will be checked automatically and pull requests without a CLA cannot be merged.

## Contribution Guidelines

Submitting code to the project? Please review and follow our
[Git commit and pull request guidelines](doc/code-submission-guidelines.md).

### Code Quality

Although we do not have official code style guidelines, we can and will request you to make changes if we feel the changes are warranted. You can take clues from the existing code base to see what we consider to be reasonable code quality. Please be prepared to make changes that we ask of you even if you might not agree with the request(s).

Please respect the coding style of the files you are changing and adhere to that.

The files in this project are formatted by [Prettier](https://prettier.io/) and [ESLint](https://eslint.org/). Both are run when code is committed. Additionally, you can run ESLint manually:

```console
npm run eslint
```

### Shadow DOM

For any proposed changes to rules, checks, commons, or other APIs to be accepted in axe-core, your code must support open Shadow DOM. See [API.md](./doc/API.md) and the [developer guide](./doc/developer-guide.md) for documentation on the available methods and test utilities. You can also look at existing tests for examples using our APIs.

### Testing

We expect all code to be 100% covered by tests. We don't have or want code coverage metrics but we will review tests and suggest changes when we think the test(s) do(es) not adequately exercise the code/code changes.

Tests should be added to the `test` directory using the same file path and name of the source file the test is for. For example, the source file `lib/commons/text/sanitize.js` should have a test file at `test/commons/text/sanitize.js`.

Axe uses Karma / Mocha / Chai as its testing framework.

### Documentation and Comments

Functions should contain a preceding comment block with [jsdoc](http://usejsdoc.org/) style documentation of the function. For example:

```js
/**
 * Runs the Audit; which in turn should call `run` on each rule.
 * @async
 * @param  {Context}   context The scope definition/context for analysis (include/exclude)
 * @param  {Object}    options Options object to pass into rules and/or disable rules or checks
 * @param  {Function} fn       Callback function to fire when audit is complete
 */
```

Classes should contain a jsdoc comment block for each attribute. For example:

```js
/**
 * Constructor for the result of checks
 * @param {Object} check CheckResult specification
 */
function CheckResult(check) {
  /**
   * ID of the check.  Unique in the context of a rule.
   * @type {String}
   */
  this.id = check.id;

  /**
   * Any data passed by Check (by calling `this.data()`)
   * @type {Mixed}
   */
  this.data = null;

  /**
   * Any node that is related to the Check, specified by calling `this.relatedNodes([HTMLElement...])` inside the Check
   * @type {Array}
   */
  this.relatedNodes = [];

  /**
   * The return value of the Check's evaluate function
   * @type {Mixed}
   */
  this.result = null;
}
```

## Setting up your environment

In order to get going, fork and clone the repository. Then, if you do not have [Node.js](https://nodejs.org/download/) installed, install it!

Once the basic infrastructure is installed, from the repository root, do the following:

```console
npm install
```

Then build the package:

```console
npm run build
```

## Developing and testing

In order to run axe tests, `axe.js` must be built using `npm run build`. To run the unit tests:

```console
npm test
```

To continually watch changes to the axe source files and re-build on changes, use:

```console
npm run develop
```

This will also rerun any tests that have been changed, and any changes to the axe source files will trigger a rerun of that files tests.

To run axe integration tests:

```console
npm run test:integration
```

Lastly, there are a few other tests that get run during the continuous integration process:

```console
# run the tests from `doc/examples/*` using the current local build of `axe.js`
npm run test:examples

# run the tests from `test/node`
npm run test:node
```

### Running and debugging specific unit tests

If you want to run a specific set of unit tests instead of all the unit tests, you can use one of the following commands:

```console
# run just the tests from `test/core`
npm run test:unit:core

# run just the tests from `test/commons`
npm run test:unit:commons

# run just the tests from `test/rule-matches`
npm run test:unit:rule-matches

# run just the tests from `test/checks`
npm run test:unit:checks

# run just the tests from `test/integration/rules`
npm run test:unit:integration

# run just the tests from `test/integration/api`
npm run test:unit:api

# run just the tests from `test/integration/virtual-rules`
npm run test:unit:virtual-rules
```

If you need to debug the unit tests in a browser, you can run:

```console
npm run test:debug
```

This will start the Karma server and open up the Chrome browser. Click the `Debug` button to start debugging the tests. You can also navigate to the listed URL in your browser of choice to debug tests using that browser.

Because the amount of tests is so large, it's recommended to debug only a specific set of unit tests rather than the whole test suite. You can use the `testDirs` argument when using the debug command and pass a specific test directory. The test directory names are the same as those used for `test:unit:*`:

```console
# accepts a single directory or a comma-separated list of directories
npm run test:debug -- testDirs=core,commons
```

## Using axe with TypeScript

### Axe Development

The TypeScript definition file for axe-core is distributed with this module and can be found in [axe.d.ts](./axe.d.ts). It currently supports TypeScript 2.0+.

You can run TypeScript definition tests using the following command:

```console
npm run test:tsc
```

## Including axe's type definition in tests

Installing axe to run accessibility tests in your TypeScript project should be as simple as importing the module:

```js
import * as axe from 'axe-core';

describe('Module', () => {
  it('should have no accessibility violations', done => {
    axe.run(compiledFixture).then(results => {
      expect(results.violations.length).toBe(0);
      done();
    }, done);
  });
});
```

## Debugging tests that only fail on CircleCI

First install an X-Windows client on your machine. XQuartz is a good one.

Then follow the [instructions here to connect the X-Windows on CircleCI to XQuartz](https://circleci.com/docs/1.0/browser-debugging/#x11-forwarding-over-ssh)

Start the build using the "Retry the build with SSH enabled" option in the CircleCI interface

Copy the SSH command and add the -X flag to it for example

```console
ssh -X -p 64605 ubuntu@13.58.157.61
```

When you login, set up the environment and start the chrome browser

```console
export DISPLAY=localhost:10.0
/opt/google/chrome/chrome
```

### .Xauthority does not exist

Edit the ~/.Xauthority file and just save it with the following commands

```console
vi ~/.Xauthority
:wq
```

### Starting the web server

Log into a second ssh terminal (without -X) and execute the following commands

```console
cd axe-core
grunt connect watch
```

Load your test file URL in the Chrome browser opened in XQuartz
