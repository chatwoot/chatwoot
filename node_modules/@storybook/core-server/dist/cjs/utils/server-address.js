"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getServerAddresses = getServerAddresses;
exports.getServerPort = exports.getServerChannelUrl = void 0;

var _ip = _interopRequireDefault(require("ip"));

var _nodeLogger = require("@storybook/node-logger");

var _detectPort = _interopRequireDefault(require("detect-port"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function getServerAddresses(port, host, proto) {
  return {
    address: `${proto}://localhost:${port}/`,
    networkAddress: `${proto}://${host || _ip.default.address()}:${port}/`
  };
}

var getServerPort = function (port) {
  return (0, _detectPort.default)(port).catch(function (error) {
    _nodeLogger.logger.error(error);

    process.exit(-1);
  });
};

exports.getServerPort = getServerPort;

var getServerChannelUrl = function (port, {
  https: https
}) {
  return `${https ? 'wss' : 'ws'}://localhost:${port}/storybook-server-channel`;
};

exports.getServerChannelUrl = getServerChannelUrl;