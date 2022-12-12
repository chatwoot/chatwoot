"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getServer = getServer;

require("core-js/modules/es.promise.js");

var _nodeLogger = require("@storybook/node-logger");

var _fsExtra = require("fs-extra");

var _http = _interopRequireDefault(require("http"));

var _https = _interopRequireDefault(require("https"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

async function getServer(app, options) {
  if (!options.https) {
    return _http.default.createServer(app);
  }

  if (!options.sslCert) {
    _nodeLogger.logger.error('Error: --ssl-cert is required with --https');

    process.exit(-1);
  }

  if (!options.sslKey) {
    _nodeLogger.logger.error('Error: --ssl-key is required with --https');

    process.exit(-1);
  }

  var sslOptions = {
    ca: await Promise.all((options.sslCa || []).map(function (ca) {
      return (0, _fsExtra.readFile)(ca, 'utf-8');
    })),
    cert: await (0, _fsExtra.readFile)(options.sslCert, 'utf-8'),
    key: await (0, _fsExtra.readFile)(options.sslKey, 'utf-8')
  };
  return _https.default.createServer(sslOptions, app);
}