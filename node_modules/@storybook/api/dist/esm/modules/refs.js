function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.symbol.to-primitive.js";
import "core-js/modules/es.date.to-primitive.js";
import "core-js/modules/es.number.constructor.js";
import "core-js/modules/es.object.freeze.js";
var _excluded = ["stories", "v"];

var _templateObject;

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

function _toPropertyKey(arg) { var key = _toPrimitive(arg, "string"); return _typeof(key) === "symbol" ? key : String(key); }

function _toPrimitive(input, hint) { if (_typeof(input) !== "object" || input === null) return input; var prim = input[Symbol.toPrimitive]; if (prim !== undefined) { var res = prim.call(input, hint || "default"); if (_typeof(res) !== "object") return res; throw new TypeError("@@toPrimitive must return a primitive value."); } return (hint === "string" ? String : Number)(input); }

import "regenerator-runtime/runtime.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.promise.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/web.url.js";
import "core-js/modules/web.url-search-params.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.replace.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.object.entries.js";
import "core-js/modules/es.array.find.js";
import "core-js/modules/es.object.values.js";
import "core-js/modules/es.string.match.js";
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.object.keys.js";
import "core-js/modules/web.dom-collections.for-each.js";
import global from 'global';
import dedent from 'ts-dedent';
import { transformStoriesRawToStoriesHash, transformStoryIndexToStoriesHash } from '../lib/stories';
var location = global.location,
    fetch = global.fetch;
// eslint-disable-next-line no-useless-escape
var findFilename = /(\/((?:[^\/]+?)\.[^\/]+?)|\/)$/;
export var getSourceType = function getSourceType(source, refId) {
  var localOrigin = location.origin,
      localPathname = location.pathname;

  var _URL = new URL(source),
      sourceOrigin = _URL.origin,
      sourcePathname = _URL.pathname;

  var localFull = "".concat(localOrigin + localPathname).replace(findFilename, '');
  var sourceFull = "".concat(sourceOrigin + sourcePathname).replace(findFilename, '');

  if (localFull === sourceFull) {
    return ['local', sourceFull];
  }

  if (refId || source) {
    return ['external', sourceFull];
  }

  return [null, null];
};
export var defaultStoryMapper = function defaultStoryMapper(b, a) {
  return Object.assign({}, a, {
    kind: a.kind.replace('|', '/')
  });
};

var addRefIds = function addRefIds(input, ref) {
  return Object.entries(input).reduce(function (acc, _ref) {
    var _ref2 = _slicedToArray(_ref, 2),
        id = _ref2[0],
        item = _ref2[1];

    return Object.assign({}, acc, _defineProperty({}, id, Object.assign({}, item, {
      refId: ref.id
    })));
  }, {});
};

var handle = /*#__PURE__*/function () {
  var _ref3 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(request) {
    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            if (!request) {
              _context.next = 2;
              break;
            }

            return _context.abrupt("return", Promise.resolve(request).then(function (response) {
              return response.ok ? response.json() : {};
            }).catch(function (error) {
              return {
                error: error
              };
            }));

          case 2:
            return _context.abrupt("return", {});

          case 3:
          case "end":
            return _context.stop();
        }
      }
    }, _callee);
  }));

  return function handle(_x) {
    return _ref3.apply(this, arguments);
  };
}();

var map = function map(input, ref, options) {
  var storyMapper = options.storyMapper;

  if (storyMapper) {
    return Object.entries(input).reduce(function (acc, _ref4) {
      var _ref5 = _slicedToArray(_ref4, 2),
          id = _ref5[0],
          item = _ref5[1];

      return Object.assign({}, acc, _defineProperty({}, id, storyMapper(ref, item)));
    }, {});
  }

  return input;
};

export var init = function init(_ref6) {
  var store = _ref6.store,
      provider = _ref6.provider,
      singleStory = _ref6.singleStory;

  var _ref7 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {},
      _ref7$runCheck = _ref7.runCheck,
      runCheck = _ref7$runCheck === void 0 ? true : _ref7$runCheck;

  var api = {
    findRef: function findRef(source) {
      var refs = api.getRefs();
      return Object.values(refs).find(function (_ref8) {
        var url = _ref8.url;
        return url.match(source);
      });
    },
    changeRefVersion: function changeRefVersion(id, url) {
      var _api$getRefs$id = api.getRefs()[id],
          versions = _api$getRefs$id.versions,
          title = _api$getRefs$id.title;
      var ref = {
        id: id,
        url: url,
        versions: versions,
        title: title,
        stories: {}
      };
      api.checkRef(ref);
    },
    changeRefState: function changeRefState(id, ready) {
      var _api$getRefs = api.getRefs(),
          ref = _api$getRefs[id],
          updated = _objectWithoutProperties(_api$getRefs, [id].map(_toPropertyKey));

      updated[id] = Object.assign({}, ref, {
        ready: ready
      });
      store.setState({
        refs: updated
      });
    },
    checkRef: function () {
      var _checkRef = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2(ref) {
        var id, url, version, type, isPublic, loadedData, query, credentials, storiesFetch, _yield$Promise$all, _yield$Promise$all2, stories, metadata, versions;

        return regeneratorRuntime.wrap(function _callee2$(_context2) {
          while (1) {
            switch (_context2.prev = _context2.next) {
              case 0:
                id = ref.id, url = ref.url, version = ref.version, type = ref.type;
                isPublic = type === 'server-checked'; // ref's type starts as either 'unknown' or 'server-checked'
                // "server-checked" happens when we were able to verify the storybook is accessible from node (without cookies)
                // "unknown" happens if the request was declined of failed (this can happen because the storybook doesn't exists or authentication is required)
                //
                // we then make a request for stories.json
                //
                // if this request fails when storybook is server-checked we mark the ref as "auto-inject", this is a fallback mechanism for local storybook, legacy storybooks, and storybooks that lack stories.json
                // if the request fails with type "unknown" we give up and show an error
                // if the request succeeds we set the ref to 'lazy' type, and show the stories in the sidebar without injecting the iframe first
                //
                // then we fetch metadata if the above fetch succeeded

                loadedData = {};
                query = version ? "?version=".concat(version) : '';
                credentials = isPublic ? 'omit' : 'include'; // In theory the `/iframe.html` could be private and the `stories.json` could not exist, but in practice
                // the only private servers we know about (Chromatic) always include `stories.json`. So we can tell
                // if the ref actually exists by simply checking `stories.json` w/ credentials.

                _context2.next = 7;
                return fetch("".concat(url, "/stories.json").concat(query), {
                  headers: {
                    Accept: 'application/json'
                  },
                  credentials: credentials
                });

              case 7:
                storiesFetch = _context2.sent;

                if (!(!storiesFetch.ok && !isPublic)) {
                  _context2.next = 12;
                  break;
                }

                loadedData.error = {
                  message: dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n            Error: Loading of ref failed\n              at fetch (lib/api/src/modules/refs.ts)\n\n            URL: ", "\n\n            We weren't able to load the above URL,\n            it's possible a CORS error happened.\n\n            Please check your dev-tools network tab.\n          "])), url)
                };
                _context2.next = 20;
                break;

              case 12:
                if (!storiesFetch.ok) {
                  _context2.next = 20;
                  break;
                }

                _context2.next = 15;
                return Promise.all([handle(storiesFetch), handle(fetch("".concat(url, "/metadata.json").concat(query), {
                  headers: {
                    Accept: 'application/json'
                  },
                  credentials: credentials,
                  cache: 'no-cache'
                }).catch(function () {
                  return false;
                }))]);

              case 15:
                _yield$Promise$all = _context2.sent;
                _yield$Promise$all2 = _slicedToArray(_yield$Promise$all, 2);
                stories = _yield$Promise$all2[0];
                metadata = _yield$Promise$all2[1];
                Object.assign(loadedData, Object.assign({}, stories, metadata));

              case 20:
                versions = ref.versions && Object.keys(ref.versions).length ? ref.versions : loadedData.versions;
                _context2.next = 23;
                return api.setRef(id, Object.assign({
                  id: id,
                  url: url
                }, loadedData, versions ? {
                  versions: versions
                } : {}, {
                  error: loadedData.error,
                  type: !loadedData.stories ? 'auto-inject' : 'lazy'
                }));

              case 23:
              case "end":
                return _context2.stop();
            }
          }
        }, _callee2);
      }));

      function checkRef(_x2) {
        return _checkRef.apply(this, arguments);
      }

      return checkRef;
    }(),
    getRefs: function getRefs() {
      var _store$getState = store.getState(),
          _store$getState$refs = _store$getState.refs,
          refs = _store$getState$refs === void 0 ? {} : _store$getState$refs;

      return refs;
    },
    setRef: function setRef(id, _ref9) {
      var ready = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;

      var stories = _ref9.stories,
          v = _ref9.v,
          rest = _objectWithoutProperties(_ref9, _excluded);

      if (singleStory) return;

      var _provider$getConfig = provider.getConfig(),
          _provider$getConfig$s = _provider$getConfig.storyMapper,
          storyMapper = _provider$getConfig$s === void 0 ? defaultStoryMapper : _provider$getConfig$s;

      var ref = api.getRefs()[id];
      var storiesHash;

      if (stories) {
        if (v === 2) {
          storiesHash = transformStoriesRawToStoriesHash(map(stories, ref, {
            storyMapper: storyMapper
          }), {
            provider: provider
          });
        } else if (!v) {
          throw new Error('Composition: Missing stories.json version');
        } else {
          var index = stories;
          storiesHash = transformStoryIndexToStoriesHash({
            v: v,
            stories: index
          }, {
            provider: provider
          });
        }

        storiesHash = addRefIds(storiesHash, ref);
      }

      api.updateRef(id, Object.assign({
        stories: storiesHash
      }, rest, {
        ready: ready
      }));
    },
    updateRef: function updateRef(id, data) {
      var _api$getRefs2 = api.getRefs(),
          ref = _api$getRefs2[id],
          updated = _objectWithoutProperties(_api$getRefs2, [id].map(_toPropertyKey));

      updated[id] = Object.assign({}, ref, data);
      /* eslint-disable no-param-reassign */

      var ordered = Object.keys(initialState).reduce(function (obj, key) {
        obj[key] = updated[key];
        return obj;
      }, {});
      /* eslint-enable no-param-reassign */

      store.setState({
        refs: ordered
      });
    }
  };
  var refs = !singleStory && provider.getConfig().refs || {};
  var initialState = refs;

  if (runCheck) {
    Object.entries(refs).forEach(function (_ref10) {
      var _ref11 = _slicedToArray(_ref10, 2),
          k = _ref11[0],
          v = _ref11[1];

      api.checkRef(v);
    });
  }

  return {
    api: api,
    state: {
      refs: initialState
    }
  };
};