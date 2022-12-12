"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getManagerHeadTemplate = getManagerHeadTemplate;
exports.getManagerMainTemplate = getManagerMainTemplate;
exports.getPreviewBodyTemplate = getPreviewBodyTemplate;
exports.getPreviewHeadTemplate = getPreviewHeadTemplate;
exports.getPreviewMainTemplate = getPreviewMainTemplate;

var _path = _interopRequireDefault(require("path"));

var _pkgDir = require("pkg-dir");

var _fs = _interopRequireDefault(require("fs"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var interpolate = function (string, data = {}) {
  return Object.entries(data).reduce(function (acc, [k, v]) {
    return acc.replace(new RegExp(`%${k}%`, 'g'), v);
  }, string);
};

function getPreviewBodyTemplate(configDirPath, interpolations) {
  var base = _fs.default.readFileSync(`${(0, _pkgDir.sync)(__dirname)}/templates/base-preview-body.html`, 'utf8');

  var bodyHtmlPath = _path.default.resolve(configDirPath, 'preview-body.html');

  var result = base;

  if (_fs.default.existsSync(bodyHtmlPath)) {
    result = _fs.default.readFileSync(bodyHtmlPath, 'utf8') + result;
  }

  return interpolate(result, interpolations);
}

function getPreviewHeadTemplate(configDirPath, interpolations) {
  var base = _fs.default.readFileSync(`${(0, _pkgDir.sync)(__dirname)}/templates/base-preview-head.html`, 'utf8');

  var headHtmlPath = _path.default.resolve(configDirPath, 'preview-head.html');

  var result = base;

  if (_fs.default.existsSync(headHtmlPath)) {
    result += _fs.default.readFileSync(headHtmlPath, 'utf8');
  }

  return interpolate(result, interpolations);
}

function getManagerHeadTemplate(configDirPath, interpolations) {
  var base = _fs.default.readFileSync(`${(0, _pkgDir.sync)(__dirname)}/templates/base-manager-head.html`, 'utf8');

  var scriptPath = _path.default.resolve(configDirPath, 'manager-head.html');

  var result = base;

  if (_fs.default.existsSync(scriptPath)) {
    result += _fs.default.readFileSync(scriptPath, 'utf8');
  }

  return interpolate(result, interpolations);
}

function getManagerMainTemplate() {
  return `${(0, _pkgDir.sync)(__dirname)}/templates/index.ejs`;
}

function getPreviewMainTemplate() {
  return `${(0, _pkgDir.sync)(__dirname)}/templates/index.ejs`;
}