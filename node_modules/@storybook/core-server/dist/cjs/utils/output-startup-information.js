"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.outputStartupInformation = outputStartupInformation;

var _chalk = _interopRequireDefault(require("chalk"));

var _nodeLogger = require("@storybook/node-logger");

var _boxen = _interopRequireDefault(require("boxen"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _cliTable = _interopRequireDefault(require("cli-table3"));

var _prettyHrtime = _interopRequireDefault(require("pretty-hrtime"));

var _updateCheck = require("./update-check");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function outputStartupInformation(options) {
  var updateInfo = options.updateInfo,
      version = options.version,
      name = options.name,
      address = options.address,
      networkAddress = options.networkAddress,
      managerTotalTime = options.managerTotalTime,
      previewTotalTime = options.previewTotalTime;
  var updateMessage = (0, _updateCheck.createUpdateMessage)(updateInfo, version);
  var serveMessage = new _cliTable.default({
    chars: {
      top: '',
      'top-mid': '',
      'top-left': '',
      'top-right': '',
      bottom: '',
      'bottom-mid': '',
      'bottom-left': '',
      'bottom-right': '',
      left: '',
      'left-mid': '',
      mid: '',
      'mid-mid': '',
      right: '',
      'right-mid': '',
      middle: ''
    },
    // @ts-ignore
    paddingLeft: 0,
    paddingRight: 0,
    paddingTop: 0,
    paddingBottom: 0
  });
  serveMessage.push(['Local:', _chalk.default.cyan(address)], ['On your network:', _chalk.default.cyan(networkAddress)]);
  var timeStatement = [managerTotalTime && `${_chalk.default.underline((0, _prettyHrtime.default)(managerTotalTime))} for manager`, previewTotalTime && `${_chalk.default.underline((0, _prettyHrtime.default)(previewTotalTime))} for preview`].filter(Boolean).join(' and '); // eslint-disable-next-line no-console

  console.log((0, _boxen.default)((0, _tsDedent.default)`
          ${_nodeLogger.colors.green(`Storybook ${_chalk.default.bold(version)} for ${_chalk.default.bold(name)} started`)}
          ${_chalk.default.gray(timeStatement)}

          ${serveMessage.toString()}${updateMessage ? `\n\n${updateMessage}` : ''}
        `, {
    borderStyle: 'round',
    padding: 1,
    borderColor: '#F1618C'
  }));
}