import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.promise.js";
import "regenerator-runtime/runtime.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

import { logger } from '@storybook/client-logger';
import { getStorybookMetadata } from './storybook-metadata';
import { sendTelemetry } from './telemetry';
import { notify } from './notify';
import { sanitizeError } from './sanitize';
export * from './storybook-metadata';
export var telemetry = /*#__PURE__*/function () {
  var _ref = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(eventType) {
    var payload,
        options,
        telemetryData,
        error,
        _process$env,
        _args = arguments;

    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            payload = _args.length > 1 && _args[1] !== undefined ? _args[1] : {};
            options = _args.length > 2 ? _args[2] : undefined;
            _context.next = 4;
            return notify();

          case 4:
            telemetryData = {
              eventType: eventType,
              payload: payload
            };
            _context.prev = 5;
            _context.next = 8;
            return getStorybookMetadata(options.configDir);

          case 8:
            telemetryData.metadata = _context.sent;
            _context.next = 14;
            break;

          case 11:
            _context.prev = 11;
            _context.t0 = _context["catch"](5);
            if (!telemetryData.payload.error) telemetryData.payload.error = _context.t0;

          case 14:
            _context.prev = 14;
            error = telemetryData.payload.error;

            if (error) {
              // make sure to anonymise possible paths from error messages
              telemetryData.payload.error = sanitizeError(error);
            }

            if (!(!telemetryData.payload.error || options !== null && options !== void 0 && options.enableCrashReports)) {
              _context.next = 25;
              break;
            }

            if (!((_process$env = process.env) !== null && _process$env !== void 0 && _process$env.STORYBOOK_DEBUG_TELEMETRY)) {
              _context.next = 23;
              break;
            }

            logger.info('\n[telemetry]');
            logger.info(JSON.stringify(telemetryData, null, 2));
            _context.next = 25;
            break;

          case 23:
            _context.next = 25;
            return sendTelemetry(telemetryData, options);

          case 25:
            return _context.finish(14);

          case 26:
          case "end":
            return _context.stop();
        }
      }
    }, _callee, null, [[5, 11, 14, 26]]);
  }));

  return function telemetry(_x) {
    return _ref.apply(this, arguments);
  };
}();