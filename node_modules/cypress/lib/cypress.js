"use strict";

// https://github.com/cypress-io/cypress/issues/316
var Promise = require('bluebird');

var tmp = Promise.promisifyAll(require('tmp'));

var fs = require('./fs');

var _open = require('./exec/open');

var _run = require('./exec/run');

var util = require('./util');

var cli = require('./cli');

var cypressModuleApi = {
  /**
   * Opens Cypress GUI
   * @see https://on.cypress.io/module-api#cypress-open
   */
  open: function open() {
    var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
    options = util.normalizeModuleOptions(options);
    return _open.start(options);
  },

  /**
   * Runs Cypress tests in the current project
   * @see https://on.cypress.io/module-api#cypress-run
   */
  run: function run() {
    var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

    if (!_run.isValidProject(options.project)) {
      return Promise.reject(new Error("Invalid project path parameter: ".concat(options.project)));
    }

    options = util.normalizeModuleOptions(options);
    return tmp.fileAsync().then(function (outputPath) {
      options.outputPath = outputPath;
      return _run.start(options).then(function (failedTests) {
        return fs.readJsonAsync(outputPath, {
          "throws": false
        }).then(function (output) {
          if (!output) {
            return {
              failures: failedTests,
              message: 'Could not find Cypress test run results'
            };
          }

          return output;
        });
      });
    });
  },
  cli: {
    /**
     * Parses CLI arguments into an object that you can pass to "cypress.run"
     * @example
     *  const cypress = require('cypress')
     *  const cli = ['cypress', 'run', '--browser', 'firefox']
     *  const options = await cypress.cli.parseRunArguments(cli)
     *  // options is {browser: 'firefox'}
     *  await cypress.run(options)
     * @see https://on.cypress.io/module-api
     */
    parseRunArguments: function parseRunArguments(args) {
      return cli.parseRunCommand(args);
    }
  }
};
module.exports = cypressModuleApi;