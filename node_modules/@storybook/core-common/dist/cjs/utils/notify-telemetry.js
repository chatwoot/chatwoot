"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.notifyTelemetry = void 0;

require("core-js/modules/es.promise.js");

var _chalk = _interopRequireDefault(require("chalk"));

var _cache = require("./cache");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var TELEMETRY_KEY_NOTIFY_DATE = 'telemetry-notification-date';
var logger = console;

var notifyTelemetry = async function () {
  var telemetryNotifyDate = await _cache.cache.get(TELEMETRY_KEY_NOTIFY_DATE, null); // The end-user has already been notified about our telemetry integration. We
  // don't need to constantly annoy them about it.
  // We will re-inform users about the telemetry if significant changes are
  // ever made.

  if (telemetryNotifyDate) {
    return;
  }

  _cache.cache.set(TELEMETRY_KEY_NOTIFY_DATE, Date.now().toString());

  logger.log(`${_chalk.default.magenta.bold('Attention')}: Storybook now collects completely anonymous telemetry regarding usage.`);
  logger.log(`This information is used to shape Storybook's roadmap and prioritize features.`);
  logger.log(`You can learn more, including how to opt-out if you'd not like to participate in this anonymous program, by visiting the following URL:`);
  logger.log(_chalk.default.cyan('https://storybook.js.org/telemetry'));
  logger.log();
};

exports.notifyTelemetry = notifyTelemetry;