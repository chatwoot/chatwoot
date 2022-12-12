"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.openInBrowser = openInBrowser;

require("core-js/modules/es.promise.js");

var _nodeLogger = require("@storybook/node-logger");

var _betterOpn = _interopRequireDefault(require("better-opn"));

var _open = _interopRequireDefault(require("open"));

var _xDefaultBrowser = _interopRequireDefault(require("x-default-browser"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// betterOpn alias used because also loading open
function openInBrowser(address) {
  (0, _xDefaultBrowser.default)(async function (err, res) {
    try {
      if (res && (res.isChrome || res.isChromium)) {
        // We use betterOpn for Chrome because it is better at handling which chrome tab
        // or window the preview loads in.
        (0, _betterOpn.default)(address);
      } else {
        await (0, _open.default)(address);
      }
    } catch (error) {
      _nodeLogger.logger.error((0, _tsDedent.default)`
        Could not open ${address} inside a browser. If you're running this command inside a
        docker container or on a CI, you need to pass the '--ci' flag to prevent opening a
        browser by default.
      `);
    }
  });
}