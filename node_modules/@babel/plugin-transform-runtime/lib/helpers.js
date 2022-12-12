"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.hasMinVersion = hasMinVersion;

const semver = require("semver");

function hasMinVersion(minVersion, runtimeVersion) {
  if (!runtimeVersion) return true;
  if (semver.valid(runtimeVersion)) runtimeVersion = `^${runtimeVersion}`;
  return !semver.intersects(`<${minVersion}`, runtimeVersion) && !semver.intersects(`>=8.0.0`, runtimeVersion);
}