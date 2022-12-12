/**
 * Wrapper for the toaster (https://github.com/nels-o/toaster)
 */
var path = require('path');
var notifier = path.resolve(__dirname, '../vendor/snoreToast/snoretoast');
var utils = require('../lib/utils');
var Balloon = require('./balloon');
var os = require('os');
const { v4: uuid } = require('uuid');

var EventEmitter = require('events').EventEmitter;
var util = require('util');

var fallback;

const PIPE_NAME = 'notifierPipe';
const PIPE_PATH_PREFIX = '\\\\.\\pipe\\';

module.exports = WindowsToaster;

function WindowsToaster(options) {
  options = utils.clone(options || {});
  if (!(this instanceof WindowsToaster)) {
    return new WindowsToaster(options);
  }

  this.options = options;

  EventEmitter.call(this);
}
util.inherits(WindowsToaster, EventEmitter);

function noop() {}

function parseResult(data) {
  if (!data) {
    return {};
  }
  return data.split(';').reduce((acc, cur) => {
    const split = cur.split('=');
    if (split && split.length === 2) {
      acc[split[0]] = split[1];
    }
    return acc;
  }, {});
}

function getPipeName() {
  return `${PIPE_PATH_PREFIX}${PIPE_NAME}-${uuid()}`;
}

function notifyRaw(options, callback) {
  options = utils.clone(options || {});
  callback = callback || noop;
  var is64Bit = os.arch() === 'x64';
  var resultBuffer;
  const server = {
    namedPipe: getPipeName()
  };

  if (typeof options === 'string') {
    options = { title: 'node-notifier', message: options };
  }

  if (typeof callback !== 'function') {
    throw new TypeError(
      'The second argument must be a function callback. You have passed ' +
        typeof fn
    );
  }

  var snoreToastResultParser = (err, callback) => {
    /* Possible exit statuses from SnoreToast, we only want to include err if it's -1 code
    Exit Status     :  Exit Code
    Failed          : -1

    Success         :  0
    Hidden          :  1
    Dismissed       :  2
    TimedOut        :  3
    ButtonPressed   :  4
    TextEntered     :  5
    */
    const result = parseResult(
      resultBuffer && resultBuffer.toString('utf16le')
    );

    // parse action
    if (result.action === 'buttonClicked' && result.button) {
      result.activationType = result.button;
    } else if (result.action) {
      result.activationType = result.action;
    }

    if (err && err.code === -1) {
      callback(err, result);
    }
    callback(null, result);

    // https://github.com/mikaelbr/node-notifier/issues/334
    // Due to an issue with snoretoast not using stdio and pipe
    // when notifications are disabled, make sure named pipe server
    // is closed before exiting.
    server.instance && server.instance.close();
  };

  var actionJackedCallback = (err) =>
    snoreToastResultParser(
      err,
      utils.actionJackerDecorator(
        this,
        options,
        callback,
        (data) => data || false
      )
    );

  options.title = options.title || 'Node Notification:';
  if (
    typeof options.message === 'undefined' &&
    typeof options.close === 'undefined'
  ) {
    callback(new Error('Message or ID to close is required.'));
    return this;
  }

  if (!utils.isWin8() && !utils.isWSL() && !!this.options.withFallback) {
    fallback = fallback || new Balloon(this.options);
    return fallback.notify(options, callback);
  }

  // Add pipeName option, to get the output
  utils.createNamedPipe(server).then((out) => {
    resultBuffer = out;
    options.pipeName = server.namedPipe;

    options = utils.mapToWin8(options);
    var argsList = utils.constructArgumentList(options, {
      explicitTrue: true,
      wrapper: '',
      keepNewlines: true,
      noEscape: true
    });

    var notifierWithArch = notifier + '-x' + (is64Bit ? '64' : '86') + '.exe';
    utils.fileCommand(
      this.options.customPath || notifierWithArch,
      argsList,
      actionJackedCallback
    );
  });
  return this;
}

Object.defineProperty(WindowsToaster.prototype, 'notify', {
  get: function () {
    if (!this._notify) this._notify = notifyRaw.bind(this);
    return this._notify;
  }
});
