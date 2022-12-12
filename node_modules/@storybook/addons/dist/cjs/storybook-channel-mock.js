"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.mockChannel = mockChannel;

var _channels = _interopRequireDefault(require("@storybook/channels"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function mockChannel() {
  var transport = {
    setHandler: function setHandler() {},
    send: function send() {}
  };
  return new _channels.default({
    transport: transport
  });
}