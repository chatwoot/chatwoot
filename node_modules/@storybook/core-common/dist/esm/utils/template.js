import path from 'path';
import { sync } from 'pkg-dir';
import fs from 'fs';

var interpolate = function (string, data = {}) {
  return Object.entries(data).reduce(function (acc, [k, v]) {
    return acc.replace(new RegExp(`%${k}%`, 'g'), v);
  }, string);
};

export function getPreviewBodyTemplate(configDirPath, interpolations) {
  var base = fs.readFileSync(`${sync(__dirname)}/templates/base-preview-body.html`, 'utf8');
  var bodyHtmlPath = path.resolve(configDirPath, 'preview-body.html');
  var result = base;

  if (fs.existsSync(bodyHtmlPath)) {
    result = fs.readFileSync(bodyHtmlPath, 'utf8') + result;
  }

  return interpolate(result, interpolations);
}
export function getPreviewHeadTemplate(configDirPath, interpolations) {
  var base = fs.readFileSync(`${sync(__dirname)}/templates/base-preview-head.html`, 'utf8');
  var headHtmlPath = path.resolve(configDirPath, 'preview-head.html');
  var result = base;

  if (fs.existsSync(headHtmlPath)) {
    result += fs.readFileSync(headHtmlPath, 'utf8');
  }

  return interpolate(result, interpolations);
}
export function getManagerHeadTemplate(configDirPath, interpolations) {
  var base = fs.readFileSync(`${sync(__dirname)}/templates/base-manager-head.html`, 'utf8');
  var scriptPath = path.resolve(configDirPath, 'manager-head.html');
  var result = base;

  if (fs.existsSync(scriptPath)) {
    result += fs.readFileSync(scriptPath, 'utf8');
  }

  return interpolate(result, interpolations);
}
export function getManagerMainTemplate() {
  return `${sync(__dirname)}/templates/index.ejs`;
}
export function getPreviewMainTemplate() {
  return `${sync(__dirname)}/templates/index.ejs`;
}