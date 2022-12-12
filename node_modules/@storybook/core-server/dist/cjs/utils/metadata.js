"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.extractStorybookMetadata = extractStorybookMetadata;
exports.useStorybookMetadata = useStorybookMetadata;

require("core-js/modules/es.promise.js");

var _fsExtra = _interopRequireDefault(require("fs-extra"));

var _telemetry = require("@storybook/telemetry");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

async function extractStorybookMetadata(outputFile, configDir) {
  var storybookMetadata = await (0, _telemetry.getStorybookMetadata)(configDir);
  await _fsExtra.default.writeJson(outputFile, storybookMetadata);
}

function useStorybookMetadata(router, configDir) {
  router.use('/project.json', async function (req, res) {
    var storybookMetadata = await (0, _telemetry.getStorybookMetadata)(configDir);
    res.header('Content-Type', 'application/json');
    res.send(JSON.stringify(storybookMetadata));
  });
}