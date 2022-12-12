import "core-js/modules/es.object.keys.js";
import "core-js/modules/es.symbol.js";
var _excluded = ["payload", "metadata"];
import "regenerator-runtime/runtime.js";

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.promise.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.filter.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

import originalFetch from 'isomorphic-unfetch';
import retry from 'fetch-retry';
import { nanoid } from 'nanoid';
import { getAnonymousProjectId } from './anonymous-id';
var URL = 'https://storybook.js.org/event-log';
var fetch = retry(originalFetch);
var tasks = []; // getStorybookMetadata -> packagejson + Main.js
// event specific data: sessionId, ip, etc..
// send telemetry

var sessionId = nanoid();
export function sendTelemetry(_x) {
  return _sendTelemetry.apply(this, arguments);
}

function _sendTelemetry() {
  _sendTelemetry = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(data) {
    var options,
        payload,
        metadata,
        rest,
        context,
        eventId,
        body,
        request,
        _args = arguments;
    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            options = _args.length > 1 && _args[1] !== undefined ? _args[1] : {
              retryDelay: 1000,
              immediate: false
            };
            // We use this id so we can de-dupe events that arrive at the index multiple times due to the
            // use of retries. There are situations in which the request "5xx"s (or times-out), but
            // the server actually gets the request and stores it anyway.
            // flatten the data before we send it
            payload = data.payload, metadata = data.metadata, rest = _objectWithoutProperties(data, _excluded);
            context = {
              anonymousId: getAnonymousProjectId(),
              inCI: process.env.CI === 'true'
            };
            eventId = nanoid();
            body = Object.assign({}, rest, {
              eventId: eventId,
              sessionId: sessionId,
              metadata: metadata,
              payload: payload,
              context: context
            });
            _context.prev = 5;
            request = fetch(URL, {
              method: 'POST',
              body: JSON.stringify(body),
              headers: {
                'Content-Type': 'application/json'
              },
              retries: 3,
              retryOn: [503, 504],
              retryDelay: function retryDelay(attempt) {
                return Math.pow(2, attempt) * options.retryDelay;
              }
            });
            tasks.push(request);

            if (!options.immediate) {
              _context.next = 13;
              break;
            }

            _context.next = 11;
            return Promise.all(tasks);

          case 11:
            _context.next = 15;
            break;

          case 13:
            _context.next = 15;
            return request;

          case 15:
            _context.next = 19;
            break;

          case 17:
            _context.prev = 17;
            _context.t0 = _context["catch"](5);

          case 19:
            _context.prev = 19;
            tasks = tasks.filter(function (task) {
              return task !== request;
            });
            return _context.finish(19);

          case 22:
          case "end":
            return _context.stop();
        }
      }
    }, _callee, null, [[5, 17, 19, 22]]);
  }));
  return _sendTelemetry.apply(this, arguments);
}