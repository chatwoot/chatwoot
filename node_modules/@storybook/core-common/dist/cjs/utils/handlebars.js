"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.handlebars = handlebars;

var _handlebars = _interopRequireDefault(require("handlebars"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function handlebars(source, data) {
  var template = _handlebars.default.compile(source);

  return template(data);
}