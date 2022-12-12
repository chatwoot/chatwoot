"use strict";

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && Symbol.iterator in Object(iter)) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { if (typeof Symbol === "undefined" || !(Symbol.iterator in Object(arr))) return; var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

var _ = require('lodash');

var R = require('ramda');

var commander = require('commander');

var _require = require('common-tags'),
    stripIndent = _require.stripIndent;

var logSymbols = require('log-symbols');

var debug = require('debug')('cypress:cli:cli');

var util = require('./util');

var logger = require('./logger');

var errors = require('./errors');

var cache = require('./tasks/cache'); // patch "commander" method called when a user passed an unknown option
// we want to print help for the current command and exit with an error


function unknownOption(flag) {
  var type = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 'option';
  if (this._allowUnknownOption) return;
  logger.error();
  logger.error("  error: unknown ".concat(type, ":"), flag);
  logger.error();
  this.outputHelp();
  util.exit(1);
}

commander.Command.prototype.unknownOption = unknownOption;

var coerceFalse = function coerceFalse(arg) {
  return arg !== 'false';
};

var coerceAnyStringToInt = function coerceAnyStringToInt(arg) {
  return typeof arg === 'string' ? parseInt(arg) : arg;
};

var spaceDelimitedArgsMsg = function spaceDelimitedArgsMsg(flag, args) {
  var msg = "\n    ".concat(logSymbols.warning, " Warning: It looks like you're passing --").concat(flag, " a space-separated list of arguments:\n\n    \"").concat(args.join(' '), "\"\n\n    This will work, but it's not recommended.\n\n    If you are trying to pass multiple arguments, separate them with commas instead:\n      cypress run --").concat(flag, " arg1,arg2,arg3\n  ");

  if (flag === 'spec') {
    msg += "\n    The most common cause of this warning is using an unescaped glob pattern. If you are\n    trying to pass a glob pattern, escape it using quotes:\n      cypress run --spec \"**/*.spec.js\"\n    ";
  }

  logger.log();
  logger.warn(stripIndent(msg));
  logger.log();
};

var parseVariableOpts = function parseVariableOpts(fnArgs, args) {
  var _fnArgs = _slicedToArray(fnArgs, 2),
      opts = _fnArgs[0],
      unknownArgs = _fnArgs[1];

  if (unknownArgs && unknownArgs.length && (opts.spec || opts.tag)) {
    // this will capture space-delimited args after
    // flags that could have possible multiple args
    // but before the next option
    // --spec spec1 spec2 or --tag foo bar
    var multiArgFlags = _.compact([opts.spec ? 'spec' : opts.spec, opts.tag ? 'tag' : opts.tag]);

    _.forEach(multiArgFlags, function (flag) {
      var argIndex = _.indexOf(args, "--".concat(flag)) + 2;

      var nextOptOffset = _.findIndex(_.slice(args, argIndex), function (arg) {
        return _.startsWith(arg, '--');
      });

      var endIndex = nextOptOffset !== -1 ? argIndex + nextOptOffset : args.length;

      var maybeArgs = _.slice(args, argIndex, endIndex);

      var extraArgs = _.intersection(maybeArgs, unknownArgs);

      if (extraArgs.length) {
        opts[flag] = [opts[flag]].concat(extraArgs);
        spaceDelimitedArgsMsg(flag, opts[flag]);
        opts[flag] = opts[flag].join(',');
      }
    });
  }

  debug('variable-length opts parsed %o', {
    args: args,
    opts: opts
  });
  return util.parseOpts(opts);
};

var descriptions = {
  browserOpenMode: 'path to a custom browser to be added to the list of available browsers in Cypress',
  browserRunMode: 'runs Cypress in the browser with the given name. if a filesystem path is supplied, Cypress will attempt to use the browser at that path.',
  cacheClear: 'delete all cached binaries',
  cacheList: 'list cached binary versions',
  cachePath: 'print the path to the binary cache',
  ciBuildId: 'the unique identifier for a run on your CI provider. typically a "BUILD_ID" env var. this value is automatically detected for most CI providers',
  config: 'sets configuration values. separate multiple values with a comma. overrides any value in cypress.json.',
  configFile: 'path to JSON file where configuration values are set. defaults to "cypress.json". pass "false" to disable.',
  detached: 'runs Cypress application in detached mode',
  dev: 'runs cypress in development and bypasses binary check',
  env: 'sets environment variables. separate multiple values with a comma. overrides any value in cypress.json or cypress.env.json',
  exit: 'keep the browser open after tests finish',
  forceInstall: 'force install the Cypress binary',
  global: 'force Cypress into global mode as if its globally installed',
  group: 'a named group for recorded runs in the Cypress Dashboard',
  headed: 'displays the browser instead of running headlessly (defaults to true for Firefox and Chromium-family browsers)',
  headless: 'hide the browser instead of running headed (defaults to true for Electron)',
  key: 'your secret Record Key. you can omit this if you set a CYPRESS_RECORD_KEY environment variable.',
  parallel: 'enables concurrent runs and automatic load balancing of specs across multiple machines or processes',
  port: 'runs Cypress on a specific port. overrides any value in cypress.json.',
  project: 'path to the project',
  quiet: 'run quietly, using only the configured reporter',
  record: 'records the run. sends test results, screenshots and videos to your Cypress Dashboard.',
  reporter: 'runs a specific mocha reporter. pass a path to use a custom reporter. defaults to "spec"',
  reporterOptions: 'options for the mocha reporter. defaults to "null"',
  spec: 'runs specific spec file(s). defaults to "all"',
  tag: 'named tag(s) for recorded runs in the Cypress Dashboard',
  version: 'prints Cypress version'
};
var knownCommands = ['cache', 'help', '-h', '--help', 'install', 'open', 'run', 'verify', '-v', '--version', 'version', 'info'];

var text = function text(description) {
  if (!descriptions[description]) {
    throw new Error("Could not find description for: ".concat(description));
  }

  return descriptions[description];
};

function includesVersion(args) {
  return _.includes(args, 'version') || _.includes(args, '--version') || _.includes(args, '-v');
}

function showVersions() {
  debug('printing Cypress version');
  return require('./exec/versions').getVersions().then(function () {
    var versions = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
    logger.always('Cypress package version:', versions["package"]);
    logger.always('Cypress binary version:', versions.binary);
    process.exit(0);
  })["catch"](util.logErrorExit1);
}

var createProgram = function createProgram() {
  var program = new commander.Command(); // bug in commander not printing name
  // in usage help docs

  program._name = 'cypress';
  program.usage('<command> [options]');
  return program;
};

var addCypressRunCommand = function addCypressRunCommand(program) {
  return program.command('run').usage('[options]').description('Runs Cypress tests from the CLI without the GUI').option('-b, --browser <browser-name-or-path>', text('browserRunMode')).option('--ci-build-id <id>', text('ciBuildId')).option('-c, --config <config>', text('config')).option('-C, --config-file <config-file>', text('configFile')).option('-e, --env <env>', text('env')).option('--group <name>', text('group')).option('-k, --key <record-key>', text('key')).option('--headed', text('headed')).option('--headless', text('headless')).option('--no-exit', text('exit')).option('--parallel', text('parallel')).option('-p, --port <port>', text('port')).option('-P, --project <project-path>', text('project')).option('-q, --quiet', text('quiet')).option('--record [bool]', text('record'), coerceFalse).option('-r, --reporter <reporter>', text('reporter')).option('-o, --reporter-options <reporter-options>', text('reporterOptions')).option('-s, --spec <spec>', text('spec')).option('-t, --tag <tag>', text('tag')).option('--dev', text('dev'), coerceFalse);
};
/**
 * Casts known command line options for "cypress run" to their intended type.
 * For example if the user passes "--port 5005" the ".port" property should be
 * a number 5005 and not a string "5005".
 *
 * Returns a clone of the original object.
 */


var castCypressRunOptions = function castCypressRunOptions(opts) {
  // only properties that have type "string | false" in our TS definition
  // require special handling, because CLI parsing takes care of purely
  // boolean arguments
  var result = R.evolve({
    port: coerceAnyStringToInt,
    configFile: coerceFalse
  })(opts);
  return result;
};

module.exports = {
  /**
   * Parses `cypress run` command line option array into an object
   * with options that you can feed into a `cypress.run()` module API call.
   * @example
   *  const options = parseRunCommand(['cypress', 'run', '--browser', 'chrome'])
   *  // options is {browser: 'chrome'}
   */
  parseRunCommand: function parseRunCommand(args) {
    return new Promise(function (resolve, reject) {
      if (!Array.isArray(args)) {
        return reject(new Error('Expected array of arguments'));
      } // make a copy of the input arguments array
      // and add placeholders where "node ..." would usually be
      // also remove "cypress" keyword at the start if present


      var cliArgs = args[0] === 'cypress' ? _toConsumableArray(args.slice(1)) : _toConsumableArray(args);
      cliArgs.unshift(null, null);
      debug('creating program parser');
      var program = createProgram();
      addCypressRunCommand(program).action(function () {
        for (var _len = arguments.length, fnArgs = new Array(_len), _key = 0; _key < _len; _key++) {
          fnArgs[_key] = arguments[_key];
        }

        debug('parsed Cypress run %o', fnArgs);
        var options = parseVariableOpts(fnArgs, cliArgs);
        debug('parsed options %o', options);
        var casted = castCypressRunOptions(options);
        debug('casted options %o', casted);
        resolve(casted);
      });
      debug('parsing args: %o', cliArgs);
      program.parse(cliArgs);
    });
  },

  /**
   * Parses the command line and kicks off Cypress process.
   */
  init: function init(args) {
    if (!args) {
      args = process.argv;
    }

    var CYPRESS_INTERNAL_ENV = process.env.CYPRESS_INTERNAL_ENV;

    if (!util.isValidCypressInternalEnvValue(CYPRESS_INTERNAL_ENV)) {
      debug('invalid CYPRESS_INTERNAL_ENV value', CYPRESS_INTERNAL_ENV);
      return errors.exitWithError(errors.errors.invalidCypressEnv)("CYPRESS_INTERNAL_ENV=".concat(CYPRESS_INTERNAL_ENV));
    }

    if (util.isNonProductionCypressInternalEnvValue(CYPRESS_INTERNAL_ENV)) {
      debug('non-production CYPRESS_INTERNAL_ENV value', CYPRESS_INTERNAL_ENV);
      var msg = "\n        ".concat(logSymbols.warning, " Warning: It looks like you're passing CYPRESS_INTERNAL_ENV=").concat(CYPRESS_INTERNAL_ENV, "\n\n        The environment variable \"CYPRESS_INTERNAL_ENV\" is reserved and should only be used internally.\n\n        Unset the \"CYPRESS_INTERNAL_ENV\" environment variable and run Cypress again.\n      ");
      logger.log();
      logger.warn(stripIndent(msg));
      logger.log();
    }

    var program = createProgram();
    program.command('help').description('Shows CLI help and exits').action(function () {
      program.help();
    });
    program.option('-v, --version', text('version')).command('version').description(text('version')).action(showVersions);
    addCypressRunCommand(program).action(function () {
      for (var _len2 = arguments.length, fnArgs = new Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
        fnArgs[_key2] = arguments[_key2];
      }

      debug('running Cypress with args %o', fnArgs);

      require('./exec/run').start(parseVariableOpts(fnArgs, args)).then(util.exit)["catch"](util.logErrorExit1);
    });
    program.command('open').usage('[options]').description('Opens Cypress in the interactive GUI.').option('-b, --browser <browser-path>', text('browserOpenMode')).option('-c, --config <config>', text('config')).option('-C, --config-file <config-file>', text('configFile')).option('-d, --detached [bool]', text('detached'), coerceFalse).option('-e, --env <env>', text('env')).option('--global', text('global')).option('-p, --port <port>', text('port')).option('-P, --project <project-path>', text('project')).option('--dev', text('dev'), coerceFalse).action(function (opts) {
      debug('opening Cypress');

      require('./exec/open').start(util.parseOpts(opts))["catch"](util.logErrorExit1);
    });
    program.command('install').usage('[options]').description('Installs the Cypress executable matching this package\'s version').option('-f, --force', text('forceInstall')).action(function (opts) {
      require('./tasks/install').start(util.parseOpts(opts))["catch"](util.logErrorExit1);
    });
    program.command('verify').usage('[options]').description('Verifies that Cypress is installed correctly and executable').option('--dev', text('dev'), coerceFalse).action(function (opts) {
      var defaultOpts = {
        force: true,
        welcomeMessage: false
      };
      var parsedOpts = util.parseOpts(opts);

      var options = _.extend(parsedOpts, defaultOpts);

      require('./tasks/verify').start(options)["catch"](util.logErrorExit1);
    });
    program.command('cache').usage('[command]').description('Manages the Cypress binary cache').option('list', text('cacheList')).option('path', text('cachePath')).option('clear', text('cacheClear')).action(function (opts, args) {
      if (!args || !args.length) {
        this.outputHelp();
        util.exit(1);
      }

      var _args = _slicedToArray(args, 1),
          command = _args[0];

      if (!_.includes(['list', 'path', 'clear'], command)) {
        unknownOption.call(this, "cache ".concat(command), 'command');
      }

      cache[command]();
    });
    program.command('info').usage('[command]').description('Prints Cypress and system information').option('--dev', text('dev'), coerceFalse).action(function (opts) {
      require('./exec/info').start(opts).then(util.exit)["catch"](util.logErrorExit1);
    });
    debug('cli starts with arguments %j', args);
    util.printNodeOptions(); // if there are no arguments

    if (args.length <= 2) {
      debug('printing help');
      program.help(); // exits
    }

    var firstCommand = args[2];

    if (!_.includes(knownCommands, firstCommand)) {
      debug('unknown command %s', firstCommand);
      logger.error('Unknown command', "\"".concat(firstCommand, "\""));
      program.outputHelp();
      return util.exit(1);
    }

    if (includesVersion(args)) {
      // commander 2.11.0 changes behavior
      // and now does not understand top level options
      // .option('-v, --version').command('version')
      // so we have to manually catch '-v, --version'
      return showVersions();
    }

    debug('program parsing arguments');
    return program.parse(args);
  }
};

if (!module.parent) {
  logger.error('This CLI module should be required from another Node module');
  logger.error('and not executed directly');
  process.exit(-1);
}