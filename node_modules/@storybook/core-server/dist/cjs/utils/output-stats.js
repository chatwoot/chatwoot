"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.outputStats = outputStats;
exports.writeStats = void 0;

require("core-js/modules/es.promise.js");

var _jsonExt = require("@discoveryjs/json-ext");

var _nodeLogger = require("@storybook/node-logger");

var _chalk = _interopRequireDefault(require("chalk"));

var _fsExtra = _interopRequireDefault(require("fs-extra"));

var _path = _interopRequireDefault(require("path"));

var _excluded = ["chunks"];

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

async function outputStats(directory, previewStats, managerStats) {
  if (previewStats) {
    var filePath = await writeStats(directory, 'preview', previewStats);

    _nodeLogger.logger.info(`=> preview stats written to ${_chalk.default.cyan(filePath)}`);
  }

  if (managerStats) {
    var _filePath = await writeStats(directory, 'manager', managerStats);

    _nodeLogger.logger.info(`=> manager stats written to ${_chalk.default.cyan(_filePath)}`);
  }
}

var writeStats = async function (directory, name, stats) {
  var filePath = _path.default.join(directory, `${name}-stats.json`);

  var _stats$toJson = stats.toJson(),
      chunks = _stats$toJson.chunks,
      data = _objectWithoutProperties(_stats$toJson, _excluded); // omit chunks, which is about half of the total data


  await new Promise(function (resolve, reject) {
    (0, _jsonExt.stringifyStream)(data, null, 2).on('error', reject).pipe(_fsExtra.default.createWriteStream(filePath)).on('error', reject).on('finish', resolve);
  });
  return filePath;
};

exports.writeStats = writeStats;