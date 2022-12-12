"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.checkAddonOrder = void 0;

require("core-js/modules/es.promise.js");

var _require = require('@storybook/node-logger'),
    logger = _require.logger;

var predicateFor = function (addon) {
  return function (entry) {
    var name = entry.name || entry;
    return name && name.includes(addon);
  };
};

var isCorrectOrder = function (addons, before, after) {
  var essentialsIndex = addons.findIndex(predicateFor('@storybook/addon-essentials'));
  var beforeIndex = addons.findIndex(predicateFor(before.name));
  var afterIndex = addons.findIndex(predicateFor(after.name));
  if (beforeIndex === -1 && before.inEssentials) beforeIndex = essentialsIndex;
  if (afterIndex === -1 && after.inEssentials) afterIndex = essentialsIndex;
  return beforeIndex !== -1 && afterIndex !== -1 && beforeIndex <= afterIndex;
};

var checkAddonOrder = async function ({
  before: before,
  after: after,
  configFile: configFile,
  getConfig: getConfig
}) {
  try {
    var config = await getConfig(configFile);

    if (!(config !== null && config !== void 0 && config.addons)) {
      logger.warn(`Unable to find 'addons' config in main Storybook config`);
      return;
    }

    if (!isCorrectOrder(config.addons, before, after)) {
      var orEssentials = " (or '@storybook/addon-essentials')";
      var beforeText = `'${before.name}'${before.inEssentials ? orEssentials : ''}`;
      var afterText = `'${after.name}'${after.inEssentials ? orEssentials : ''}`;
      logger.warn(`Expected ${beforeText} to be listed before ${afterText} in main Storybook config.`);
    }
  } catch (e) {
    logger.warn(`Unable to load config file: ${configFile}`);
  }
};

exports.checkAddonOrder = checkAddonOrder;