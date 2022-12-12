"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getAnonymousProjectId = void 0;

require("core-js/modules/es.array.concat.js");

require("core-js/modules/es.string.trim.js");

var _path = _interopRequireDefault(require("path"));

var _child_process = require("child_process");

var _coreCommon = require("@storybook/core-common");

var _oneWayHash = require("./one-way-hash");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var anonymousProjectId;

var getAnonymousProjectId = function getAnonymousProjectId() {
  if (anonymousProjectId) {
    return anonymousProjectId;
  }

  var unhashedProjectId;

  try {
    var projectRoot = (0, _coreCommon.getProjectRoot)();

    var projectRootPath = _path.default.relative(projectRoot, process.cwd());

    var originBuffer = (0, _child_process.execSync)("git config --local --get remote.origin.url", {
      timeout: 1000,
      stdio: "pipe"
    }); // we use a combination of remoteUrl and working directory
    // to separate multiple storybooks from the same project (e.g. monorepo)

    unhashedProjectId = "".concat(String(originBuffer).trim()).concat(projectRootPath);
    anonymousProjectId = (0, _oneWayHash.oneWayHash)(unhashedProjectId);
  } catch (_) {//
  }

  return anonymousProjectId;
};

exports.getAnonymousProjectId = getAnonymousProjectId;