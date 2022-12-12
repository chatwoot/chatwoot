"use strict";

var _server = require("@storybook/core/server");

var _options = _interopRequireDefault(require("./options"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

(0, _server.buildStatic)(_options.default);