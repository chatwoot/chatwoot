"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.serverRequire = serverRequire;
exports.serverResolve = serverResolve;

var _interpret = _interopRequireDefault(require("interpret"));

var _path = _interopRequireDefault(require("path"));

var _nodeLogger = require("@storybook/node-logger");

var _interpretFiles = require("./interpret-files");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// The code based on https://github.com/webpack/webpack-cli/blob/ca504de8c7c0ea66278021b72fa6a953e3ffa43c/bin/convert-argv
var compilersState = new Map();

function registerCompiler(moduleDescriptor) {
  if (!moduleDescriptor) {
    return 0;
  }

  var state = compilersState.get(moduleDescriptor);

  if (state !== undefined) {
    return state;
  }

  if (typeof moduleDescriptor === 'string') {
    // eslint-disable-next-line import/no-dynamic-require,global-require
    require(moduleDescriptor);

    compilersState.set(moduleDescriptor, 1);
    return 1;
  }

  if (!Array.isArray(moduleDescriptor)) {
    // eslint-disable-next-line import/no-dynamic-require,global-require
    moduleDescriptor.register(require(moduleDescriptor.module));
    compilersState.set(moduleDescriptor, 1);
    return 1;
  }

  var registered = 0;

  for (var i = 0; i < moduleDescriptor.length; i += 1) {
    try {
      registered += registerCompiler(moduleDescriptor[i]);
      break;
    } catch (e) {// do nothing
    }
  }

  compilersState.set(moduleDescriptor, registered);
  return registered;
}

function interopRequireDefault(filePath) {
  // eslint-disable-next-line import/no-dynamic-require,global-require
  var result = require(filePath);

  var isES6DefaultExported = typeof result === 'object' && result !== null && typeof result.default !== 'undefined';
  return isES6DefaultExported ? result.default : result;
}

function getCandidate(paths) {
  for (var i = 0; i < paths.length; i += 1) {
    var candidate = (0, _interpretFiles.getInterpretedFileWithExt)(paths[i]);

    if (candidate) {
      return candidate;
    }
  }

  return undefined;
}

function serverRequire(filePath) {
  var candidatePath = serverResolve(filePath);

  if (!candidatePath) {
    return null;
  }

  var candidateExt = _path.default.extname(candidatePath);

  var moduleDescriptor = _interpret.default.extensions[candidateExt]; // The "moduleDescriptor" either "undefined" or "null". The warning isn't needed in these cases.

  if (moduleDescriptor && registerCompiler(moduleDescriptor) === 0) {
    _nodeLogger.logger.warn(`=> File ${candidatePath} is detected`);

    _nodeLogger.logger.warn(`   but impossible to import loader for ${candidateExt}`);

    return null;
  }

  return interopRequireDefault(candidatePath);
}

function serverResolve(filePath) {
  var paths = Array.isArray(filePath) ? filePath : [filePath];
  var existingCandidate = getCandidate(paths);

  if (!existingCandidate) {
    return null;
  }

  return existingCandidate.path;
}