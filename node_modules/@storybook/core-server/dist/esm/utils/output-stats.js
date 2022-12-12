var _excluded = ["chunks"];

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import "core-js/modules/es.promise.js";
import { stringifyStream } from '@discoveryjs/json-ext';
import { logger } from '@storybook/node-logger';
import chalk from 'chalk';
import fs from 'fs-extra';
import path from 'path';
export async function outputStats(directory, previewStats, managerStats) {
  if (previewStats) {
    var filePath = await writeStats(directory, 'preview', previewStats);
    logger.info(`=> preview stats written to ${chalk.cyan(filePath)}`);
  }

  if (managerStats) {
    var _filePath = await writeStats(directory, 'manager', managerStats);

    logger.info(`=> manager stats written to ${chalk.cyan(_filePath)}`);
  }
}
export var writeStats = async function (directory, name, stats) {
  var filePath = path.join(directory, `${name}-stats.json`);

  var _stats$toJson = stats.toJson(),
      chunks = _stats$toJson.chunks,
      data = _objectWithoutProperties(_stats$toJson, _excluded); // omit chunks, which is about half of the total data


  await new Promise(function (resolve, reject) {
    stringifyStream(data, null, 2).on('error', reject).pipe(fs.createWriteStream(filePath)).on('error', reject).on('finish', resolve);
  });
  return filePath;
};