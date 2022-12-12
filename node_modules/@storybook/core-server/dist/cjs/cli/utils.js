"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.checkDeprecatedFlags = checkDeprecatedFlags;
exports.getEnvConfig = getEnvConfig;
exports.parseList = parseList;

var _utilDeprecate = _interopRequireDefault(require("util-deprecate"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function parseList(str) {
  return str.split(',').map(function (item) {
    return item.trim();
  }).filter(function (item) {
    return item.length > 0;
  });
}

function getEnvConfig(program, configEnv) {
  Object.keys(configEnv).forEach(function (fieldName) {
    var envVarName = configEnv[fieldName];
    var envVarValue = process.env[envVarName];

    if (envVarValue) {
      program[fieldName] = envVarValue; // eslint-disable-line
    }
  });
}

var warnDeprecatedFlag = function (message) {
  return (0, _utilDeprecate.default)(function () {}, (0, _tsDedent.default)(message));
};

var warnDLLsDeprecated = warnDeprecatedFlag(`
    DLL-related CLI flags are deprecated, see:
    
    https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-dll-flags
  `);
var warnStaticDirDeprecated = warnDeprecatedFlag(`
    --static-dir CLI flag is deprecated, see:

    https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated---static-dir-cli-flag
  `);

function checkDeprecatedFlags({
  dll: dll,
  uiDll: uiDll,
  docsDll: docsDll,
  staticDir: staticDir
}) {
  if (!dll || uiDll || docsDll) {
    warnDLLsDeprecated();
  }

  if (staticDir) {
    warnStaticDirDeprecated();
  }
}