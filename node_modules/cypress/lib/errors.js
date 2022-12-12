"use strict";

function _templateObject17() {
  var data = _taggedTemplateLiteral(["\n      To skip the binary install, set CYPRESS_INSTALL_BINARY=0\n    "]);

  _templateObject17 = function _templateObject17() {
    return data;
  };

  return data;
}

function _templateObject16() {
  var data = _taggedTemplateLiteral(["\n    The environment variable CYPRESS_SKIP_BINARY_INSTALL has been removed as of version ", "\n    "]);

  _templateObject16 = function _templateObject16() {
    return data;
  };

  return data;
}

function _templateObject15() {
  var data = _taggedTemplateLiteral(["\n    You should set CYPRESS_INSTALL_BINARY instead.\n    "]);

  _templateObject15 = function _templateObject15() {
    return data;
  };

  return data;
}

function _templateObject14() {
  var data = _taggedTemplateLiteral(["\n    The environment variable CYPRESS_BINARY_VERSION has been renamed to CYPRESS_INSTALL_BINARY as of version ", "\n    "]);

  _templateObject14 = function _templateObject14() {
    return data;
  };

  return data;
}

function _templateObject13() {
  var data = _taggedTemplateLiteral(["\n  Please search Cypress documentation for possible solutions:\n\n    ", "\n\n  Check if there is a GitHub issue describing this crash:\n\n    ", "\n\n  Consider opening a new issue.\n"]);

  _templateObject13 = function _templateObject13() {
    return data;
  };

  return data;
}

function _templateObject12() {
  var data = _taggedTemplateLiteral(["\n    See discussion and possible solutions at\n    ", "\n  "]);

  _templateObject12 = function _templateObject12() {
    return data;
  };

  return data;
}

function _templateObject11() {
  var data = _taggedTemplateLiteral(["\n    This is usually caused by a missing library or dependency.\n\n    The error below should indicate which dependency is missing.\n\n      ", "\n\n    If you are using Docker, we provide containers with all required dependencies installed.\n  "]);

  _templateObject11 = function _templateObject11() {
    return data;
  };

  return data;
}

function _templateObject10() {
  var data = _taggedTemplateLiteral(["\n      Cypress failed to start after spawning a new Xvfb server.\n\n      The error logs we received were:\n\n      ", "\n\n      ", "\n\n      ", "\n\n      This is usually caused by a missing library or dependency.\n\n      The error above should indicate which dependency is missing.\n\n        ", "\n\n      If you are using Docker, we provide containers with all required dependencies installed.\n    "]);

  _templateObject10 = function _templateObject10() {
    return data;
  };

  return data;
}

function _templateObject9() {
  var data = _taggedTemplateLiteral(["\n    This command failed with the following output:\n\n    ", "\n\n    "]);

  _templateObject9 = function _templateObject9() {
    return data;
  };

  return data;
}

function _templateObject8() {
  var data = _taggedTemplateLiteral(["\n    Install Xvfb and run Cypress again.\n\n    Read our documentation on dependencies for more information:\n\n      ", "\n\n    If you are using Docker, we provide containers with all required dependencies installed.\n    "]);

  _templateObject8 = function _templateObject8() {
    return data;
  };

  return data;
}

function _templateObject7() {
  var data = _taggedTemplateLiteral(["\n    There was a problem spawning Xvfb.\n\n    This is likely a problem with your system, permissions, or installation of Xvfb.\n    "]);

  _templateObject7 = function _templateObject7() {
    return data;
  };

  return data;
}

function _templateObject6() {
  var data = _taggedTemplateLiteral(["\n\n    We expected the binary to be installed here: ", "\n\n    Reasons it may be missing:\n\n    - You're caching 'node_modules' but are not caching this path: ", "\n    - You ran 'npm install' at an earlier build step but did not persist: ", "\n\n    Properly caching the binary will fix this error and avoid downloading and unzipping Cypress.\n\n    Alternatively, you can run 'cypress install' to download the binary again.\n\n    ", "\n  "], ["\\n\n    We expected the binary to be installed here: ", "\n\n    Reasons it may be missing:\n\n    - You're caching 'node_modules' but are not caching this path: ", "\n    - You ran 'npm install' at an earlier build step but did not persist: ", "\n\n    Properly caching the binary will fix this error and avoid downloading and unzipping Cypress.\n\n    Alternatively, you can run 'cypress install' to download the binary again.\n\n    ", "\n  "]);

  _templateObject6 = function _templateObject6() {
    return data;
  };

  return data;
}

function _templateObject5() {
  var data = _taggedTemplateLiteral(["\n\n    Reasons this may happen:\n\n    - node was installed as 'root' or with 'sudo'\n    - the cypress npm package as 'root' or with 'sudo'\n\n    Please check that you have the appropriate user permissions.\n  "], ["\\n\n    Reasons this may happen:\n\n    - node was installed as 'root' or with 'sudo'\n    - the cypress npm package as 'root' or with 'sudo'\n\n    Please check that you have the appropriate user permissions.\n  "]);

  _templateObject5 = function _templateObject5() {
    return data;
  };

  return data;
}

function _templateObject4() {
  var data = _taggedTemplateLiteral(["\n    \nPlease reinstall Cypress by running: ", "\n  "], ["\n    \\nPlease reinstall Cypress by running: ", "\n  "]);

  _templateObject4 = function _templateObject4() {
    return data;
  };

  return data;
}

function _templateObject3() {
  var data = _taggedTemplateLiteral(["\n  Does your workplace require a proxy to be used to access the Internet? If so, you must configure the HTTP_PROXY environment variable before downloading Cypress. Read more: https://on.cypress.io/proxy-configuration\n\n  Otherwise, please check network connectivity and try again:"]);

  _templateObject3 = function _templateObject3() {
    return data;
  };

  return data;
}

function _templateObject2() {
  var data = _taggedTemplateLiteral(["\n    Please provide a valid project path.\n\n    Learn more about ", " at:\n\n      ", "\n  "]);

  _templateObject2 = function _templateObject2() {
    return data;
  };

  return data;
}

function _templateObject() {
  var data = _taggedTemplateLiteral(["\n  Search for an existing issue or open a GitHub issue at\n\n    ", "\n"]);

  _templateObject = function _templateObject() {
    return data;
  };

  return data;
}

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

var chalk = require('chalk');

var _require = require('common-tags'),
    stripIndent = _require.stripIndent,
    stripIndents = _require.stripIndents;

var _require2 = require('ramda'),
    merge = _require2.merge;

var la = require('lazy-ass');

var is = require('check-more-types');

var util = require('./util');

var state = require('./tasks/state');

var docsUrl = 'https://on.cypress.io';
var requiredDependenciesUrl = "".concat(docsUrl, "/required-dependencies");
var runDocumentationUrl = "".concat(docsUrl, "/cypress-run"); // TODO it would be nice if all error objects could be enforced via types
// to only have description + solution properties

var hr = '----------';
var genericErrorSolution = stripIndent(_templateObject(), chalk.blue(util.issuesUrl)); // common errors Cypress application can encounter

var unknownError = {
  description: 'Unknown Cypress CLI error',
  solution: genericErrorSolution
};
var invalidRunProjectPath = {
  description: 'Invalid --project path',
  solution: stripIndent(_templateObject2(), chalk.cyan('cypress run'), chalk.blue(runDocumentationUrl))
};
var failedDownload = {
  description: 'The Cypress App could not be downloaded.',
  solution: stripIndent(_templateObject3())
};
var failedUnzip = {
  description: 'The Cypress App could not be unzipped.',
  solution: genericErrorSolution
};

var missingApp = function missingApp(binaryDir) {
  return {
    description: "No version of Cypress is installed in: ".concat(chalk.cyan(binaryDir)),
    solution: stripIndent(_templateObject4(), chalk.cyan('cypress install'))
  };
};

var binaryNotExecutable = function binaryNotExecutable(executable) {
  return {
    description: "Cypress cannot run because this binary file does not have executable permissions here:\n\n".concat(executable),
    solution: stripIndent(_templateObject5())
  };
};

var notInstalledCI = function notInstalledCI(executable) {
  return {
    description: 'The cypress npm package is installed, but the Cypress binary is missing.',
    solution: stripIndent(_templateObject6(), chalk.cyan(executable), util.getCacheDir(), util.getCacheDir(), chalk.blue('https://on.cypress.io/not-installed-ci-error'))
  };
};

var nonZeroExitCodeXvfb = {
  description: 'Xvfb exited with a non zero exit code.',
  solution: stripIndent(_templateObject7())
};
var missingXvfb = {
  description: 'Your system is missing the dependency: Xvfb',
  solution: stripIndent(_templateObject8(), chalk.blue(requiredDependenciesUrl))
};

var smokeTestFailure = function smokeTestFailure(smokeTestCommand, timedOut) {
  return {
    description: "Cypress verification ".concat(timedOut ? 'timed out' : 'failed', "."),
    solution: stripIndent(_templateObject9(), smokeTestCommand)
  };
};

var invalidSmokeTestDisplayError = {
  code: 'INVALID_SMOKE_TEST_DISPLAY_ERROR',
  description: 'Cypress verification failed.',
  solution: function solution(msg) {
    return stripIndent(_templateObject10(), hr, msg, hr, chalk.blue(requiredDependenciesUrl));
  }
};
var missingDependency = {
  description: 'Cypress failed to start.',
  // this message is too Linux specific
  solution: stripIndent(_templateObject11(), chalk.blue(requiredDependenciesUrl))
};
var invalidCacheDirectory = {
  description: 'Cypress cannot write to the cache directory due to file permissions',
  solution: stripIndent(_templateObject12(), chalk.blue(util.getGitHubIssueUrl(1281)))
};
var versionMismatch = {
  description: 'Installed version does not match package version.',
  solution: 'Install Cypress and verify app again'
};
var incompatibleHeadlessFlags = {
  description: '`--headed` and `--headless` cannot both be passed.',
  solution: 'Either pass `--headed` or `--headless`, but not both.'
};
var solutionUnknown = stripIndent(_templateObject13(), chalk.blue(docsUrl), chalk.blue(util.issuesUrl));
var unexpected = {
  description: 'An unexpected error occurred while verifying the Cypress executable.',
  solution: solutionUnknown
};
var invalidCypressEnv = {
  description: chalk.red('The environment variable with the reserved name "CYPRESS_INTERNAL_ENV" is set.'),
  solution: chalk.red('Unset the "CYPRESS_INTERNAL_ENV" environment variable and run Cypress again.'),
  exitCode: 11
};
/**
 * This error happens when CLI detects that the child Test Runner process
 * was killed with a signal, like SIGBUS
 * @see https://github.com/cypress-io/cypress/issues/5808
 * @param {'close'|'event'} eventName Child close event name
 * @param {string} signal Signal that closed the child process, like "SIGBUS"
*/

var childProcessKilled = function childProcessKilled(eventName, signal) {
  return {
    description: "The Test Runner unexpectedly exited via a ".concat(chalk.cyan(eventName), " event with signal ").concat(chalk.cyan(signal)),
    solution: solutionUnknown
  };
};

var removed = {
  CYPRESS_BINARY_VERSION: {
    description: stripIndent(_templateObject14(), chalk.green('3.0.0')),
    solution: stripIndent(_templateObject15())
  },
  CYPRESS_SKIP_BINARY_INSTALL: {
    description: stripIndent(_templateObject16(), chalk.green('3.0.0')),
    solution: stripIndent(_templateObject17())
  }
};
var CYPRESS_RUN_BINARY = {
  notValid: function notValid(value) {
    var properFormat = "**/".concat(state.getPlatformExecutable());
    return {
      description: "Could not run binary set by environment variable: CYPRESS_RUN_BINARY=".concat(value),
      solution: "Ensure the environment variable is a path to the Cypress binary, matching ".concat(properFormat)
    };
  }
};

function addPlatformInformation(info) {
  return util.getPlatformInfo().then(function (platform) {
    return merge(info, {
      platform: platform
    });
  });
}
/**
 * Given an error object (see the errors above), forms error message text with details,
 * then resolves with Error instance you can throw or reject with.
 * @param {object} errorObject
 * @returns {Promise<Error>} resolves with an Error
 * @example
  ```js
  // inside a Promise with "resolve" and "reject"
  const errorObject = childProcessKilled('exit', 'SIGKILL')
  return getError(errorObject).then(reject)
  ```
 */


function getError(errorObject) {
  return formErrorText(errorObject).then(function (errorMessage) {
    var err = new Error(errorMessage);
    err.known = true;
    return err;
  });
}
/**
 * Forms nice error message with error and platform information,
 * and if possible a way to solve it. Resolves with a string.
 */


function formErrorText(info, msg, prevMessage) {
  return addPlatformInformation(info).then(function (obj) {
    var formatted = [];

    function add(msg) {
      formatted.push(stripIndents(msg));
    }

    la(is.unemptyString(obj.description), 'expected error description to be text', obj.description); // assuming that if there the solution is a function it will handle
    // error message and (optional previous error message)

    if (is.fn(obj.solution)) {
      var text = obj.solution(msg, prevMessage);
      la(is.unemptyString(text), 'expected solution to be text', text);
      add("\n        ".concat(obj.description, "\n\n        ").concat(text, "\n\n      "));
    } else {
      la(is.unemptyString(obj.solution), 'expected error solution to be text', obj.solution);
      add("\n        ".concat(obj.description, "\n\n        ").concat(obj.solution, "\n\n      "));

      if (msg) {
        add("\n          ".concat(hr, "\n\n          ").concat(msg, "\n\n        "));
      }
    }

    add("\n      ".concat(hr, "\n\n      ").concat(obj.platform, "\n    "));

    if (obj.footer) {
      add("\n\n        ".concat(hr, "\n\n        ").concat(obj.footer, "\n      "));
    }

    return formatted.join('\n\n');
  });
}

var raise = function raise(info) {
  return function (text) {
    var err = new Error(text);

    if (info.code) {
      err.code = info.code;
    }

    err.known = true;
    throw err;
  };
};

var throwFormErrorText = function throwFormErrorText(info) {
  return function (msg, prevMessage) {
    return formErrorText(info, msg, prevMessage).then(raise(info));
  };
};
/**
 * Forms full error message with error and OS details, prints to the error output
 * and then exits the process.
 * @param {ErrorInformation} info Error information {description, solution}
 * @example return exitWithError(errors.invalidCypressEnv)('foo')
 */


var exitWithError = function exitWithError(info) {
  return function (msg) {
    return formErrorText(info, msg).then(function (text) {
      // eslint-disable-next-line no-console
      console.error(text);
      process.exit(info.exitCode || 1);
    });
  };
};

module.exports = {
  raise: raise,
  exitWithError: exitWithError,
  // formError,
  formErrorText: formErrorText,
  throwFormErrorText: throwFormErrorText,
  getError: getError,
  hr: hr,
  errors: {
    unknownError: unknownError,
    nonZeroExitCodeXvfb: nonZeroExitCodeXvfb,
    missingXvfb: missingXvfb,
    missingApp: missingApp,
    notInstalledCI: notInstalledCI,
    missingDependency: missingDependency,
    invalidSmokeTestDisplayError: invalidSmokeTestDisplayError,
    versionMismatch: versionMismatch,
    binaryNotExecutable: binaryNotExecutable,
    unexpected: unexpected,
    failedDownload: failedDownload,
    failedUnzip: failedUnzip,
    invalidCypressEnv: invalidCypressEnv,
    invalidCacheDirectory: invalidCacheDirectory,
    removed: removed,
    CYPRESS_RUN_BINARY: CYPRESS_RUN_BINARY,
    smokeTestFailure: smokeTestFailure,
    childProcessKilled: childProcessKilled,
    incompatibleHeadlessFlags: incompatibleHeadlessFlags,
    invalidRunProjectPath: invalidRunProjectPath
  }
};