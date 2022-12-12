import "core-js/modules/es.symbol.js";
var _excluded = ["id"],
    _excluded2 = ["kind", "story", "storyId"];

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import "regenerator-runtime/runtime.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.promise.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.object.keys.js";
import "core-js/modules/es.array.find.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.split.js";
import "core-js/modules/es.array.includes.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.array.find-index.js";
import "core-js/modules/es.string.includes.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.set.js";
import "core-js/modules/web.dom-collections.iterator.js";
import global from 'global';
import { toId, sanitize } from '@storybook/csf';
import { PRELOAD_STORIES, STORY_PREPARED, UPDATE_STORY_ARGS, RESET_STORY_ARGS, STORY_ARGS_UPDATED, STORY_CHANGED, SELECT_STORY, SET_STORIES, STORY_SPECIFIED, STORY_INDEX_INVALIDATED, CONFIG_ERROR } from '@storybook/core-events';
import deprecate from 'util-deprecate';
import { logger } from '@storybook/client-logger';
import { getEventMetadata } from '../lib/events';
import { denormalizeStoryParameters, transformStoriesRawToStoriesHash, isStory, isRoot, transformStoryIndexToStoriesHash, getComponentLookupList, getStoriesLookupList } from '../lib/stories';
var DOCS_MODE = global.DOCS_MODE,
    FEATURES = global.FEATURES,
    fetch = global.fetch;
var STORY_INDEX_PATH = './stories.json';
var deprecatedOptionsParameterWarnings = ['enableShortcuts', 'theme', 'showRoots'].reduce(function (acc, option) {
  acc[option] = deprecate(function () {}, "parameters.options.".concat(option, " is deprecated and will be removed in Storybook 7.0.\nTo change this setting, use `addons.setConfig`. See https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-immutable-options-parameters\n  "));
  return acc;
}, {});

function checkDeprecatedOptionParameters(options) {
  if (!options) {
    return;
  }

  Object.keys(options).forEach(function (option) {
    if (deprecatedOptionsParameterWarnings[option]) {
      deprecatedOptionsParameterWarnings[option]();
    }
  });
}

export var init = function init(_ref) {
  var fullAPI = _ref.fullAPI,
      store = _ref.store,
      navigate = _ref.navigate,
      provider = _ref.provider,
      initialStoryId = _ref.storyId,
      initialViewMode = _ref.viewMode;
  var api = {
    storyId: toId,
    getData: function getData(storyId, refId) {
      var result = api.resolveStory(storyId, refId);
      return isRoot(result) ? undefined : result;
    },
    isPrepared: function isPrepared(storyId, refId) {
      var data = api.getData(storyId, refId);

      if (data.isLeaf) {
        return data.prepared;
      } // Groups are always prepared :shrug:


      return true;
    },
    resolveStory: function resolveStory(storyId, refId) {
      var _store$getState = store.getState(),
          refs = _store$getState.refs,
          storiesHash = _store$getState.storiesHash;

      if (refId) {
        return refs[refId].stories ? refs[refId].stories[storyId] : undefined;
      }

      return storiesHash ? storiesHash[storyId] : undefined;
    },
    getCurrentStoryData: function getCurrentStoryData() {
      var _store$getState2 = store.getState(),
          storyId = _store$getState2.storyId,
          refId = _store$getState2.refId;

      return api.getData(storyId, refId);
    },
    getParameters: function getParameters(storyIdOrCombo, parameterName) {
      var _ref2 = typeof storyIdOrCombo === 'string' ? {
        storyId: storyIdOrCombo,
        refId: undefined
      } : storyIdOrCombo,
          storyId = _ref2.storyId,
          refId = _ref2.refId;

      var data = api.getData(storyId, refId);

      if (isStory(data)) {
        var parameters = data.parameters;

        if (parameters) {
          return parameterName ? parameters[parameterName] : parameters;
        }

        return {};
      }

      return null;
    },
    getCurrentParameter: function getCurrentParameter(parameterName) {
      var _store$getState3 = store.getState(),
          storyId = _store$getState3.storyId,
          refId = _store$getState3.refId;

      var parameters = api.getParameters({
        storyId: storyId,
        refId: refId
      }, parameterName); // FIXME Returning falsey parameters breaks a bunch of toolbars code,
      // so this strange logic needs to be here until various client code is updated.

      return parameters || undefined;
    },
    jumpToComponent: function jumpToComponent(direction) {
      var _store$getState4 = store.getState(),
          storiesHash = _store$getState4.storiesHash,
          storyId = _store$getState4.storyId,
          refs = _store$getState4.refs,
          refId = _store$getState4.refId;

      var story = api.getData(storyId, refId); // cannot navigate when there's no current selection

      if (!story) {
        return;
      }

      var hash = refId ? refs[refId].stories || {} : storiesHash;
      var result = api.findSiblingStoryId(storyId, hash, direction, true);

      if (result) {
        api.selectStory(result, undefined, {
          ref: refId
        });
      }
    },
    jumpToStory: function jumpToStory(direction) {
      var _store$getState5 = store.getState(),
          storiesHash = _store$getState5.storiesHash,
          storyId = _store$getState5.storyId,
          refs = _store$getState5.refs,
          refId = _store$getState5.refId;

      var story = api.getData(storyId, refId);

      if (DOCS_MODE) {
        api.jumpToComponent(direction);
        return;
      } // cannot navigate when there's no current selection


      if (!story) {
        return;
      }

      var hash = story.refId ? refs[story.refId].stories : storiesHash;
      var result = api.findSiblingStoryId(storyId, hash, direction, false);

      if (result) {
        api.selectStory(result, undefined, {
          ref: refId
        });
      }
    },
    setStories: function () {
      var _setStories = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(input, error) {
        var hash;
        return regeneratorRuntime.wrap(function _callee$(_context) {
          while (1) {
            switch (_context.prev = _context.next) {
              case 0:
                // Now create storiesHash by reordering the above by group
                hash = transformStoriesRawToStoriesHash(input, {
                  provider: provider
                });
                _context.next = 3;
                return store.setState({
                  storiesHash: hash,
                  storiesConfigured: true,
                  storiesFailed: error
                });

              case 3:
              case "end":
                return _context.stop();
            }
          }
        }, _callee);
      }));

      function setStories(_x, _x2) {
        return _setStories.apply(this, arguments);
      }

      return setStories;
    }(),
    selectFirstStory: function selectFirstStory() {
      var _store$getState6 = store.getState(),
          storiesHash = _store$getState6.storiesHash;

      var firstStory = Object.keys(storiesHash).find(function (k) {
        return !(storiesHash[k].children || Array.isArray(storiesHash[k]));
      });

      if (firstStory) {
        api.selectStory(firstStory);
        return;
      }

      navigate('/');
    },
    selectStory: function selectStory() {
      var kindOrId = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : undefined;
      var story = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : undefined;
      var options = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : {};
      var ref = options.ref,
          viewModeFromArgs = options.viewMode;

      var _store$getState7 = store.getState(),
          _store$getState7$view = _store$getState7.viewMode,
          viewModeFromState = _store$getState7$view === void 0 ? 'story' : _store$getState7$view,
          storyId = _store$getState7.storyId,
          storiesHash = _store$getState7.storiesHash,
          refs = _store$getState7.refs;

      var hash = ref ? refs[ref].stories : storiesHash;
      var kindSlug = storyId === null || storyId === void 0 ? void 0 : storyId.split('--', 2)[0];

      if (!story) {
        var s = kindOrId ? hash[kindOrId] || hash[sanitize(kindOrId)] : hash[kindSlug]; // eslint-disable-next-line no-nested-ternary

        var id = s ? s.children ? s.children[0] : s.id : kindOrId;
        var viewMode = s && !isRoot(s) && (viewModeFromArgs || s.parameters.viewMode) ? s.parameters.viewMode : viewModeFromState; // Some viewModes are not story-specific, and we should reset viewMode
        //  to 'story' if one of those is active when navigating to another story

        if (['settings', 'about', 'release'].includes(viewMode)) {
          viewMode = 'story';
        }

        var p = s && s.refId ? "/".concat(viewMode, "/").concat(s.refId, "_").concat(id) : "/".concat(viewMode, "/").concat(id);
        navigate(p);
      } else if (!kindOrId) {
        // This is a slugified version of the kind, but that's OK, our toId function is idempotent
        var _id = toId(kindSlug, story);

        api.selectStory(_id, undefined, options);
      } else {
        var _id2 = ref ? "".concat(ref, "_").concat(toId(kindOrId, story)) : toId(kindOrId, story);

        if (hash[_id2]) {
          api.selectStory(_id2, undefined, options);
        } else {
          // Support legacy API with component permalinks, where kind is `x/y` but permalink is 'z'
          var _k = hash[sanitize(kindOrId)];

          if (_k && _k.children) {
            var foundId = _k.children.find(function (childId) {
              return hash[childId].name === story;
            });

            if (foundId) {
              api.selectStory(foundId, undefined, options);
            }
          }
        }
      }
    },
    findLeafStoryId: function findLeafStoryId(storiesHash, storyId) {
      if (storiesHash[storyId].isLeaf) {
        return storyId;
      }

      var childStoryId = storiesHash[storyId].children[0];
      return api.findLeafStoryId(storiesHash, childStoryId);
    },
    findSiblingStoryId: function findSiblingStoryId(storyId, hash, direction, toSiblingGroup) {
      if (toSiblingGroup) {
        var _lookupList = getComponentLookupList(hash);

        var _index = _lookupList.findIndex(function (i) {
          return i.includes(storyId);
        }); // cannot navigate beyond fist or last


        if (_index === _lookupList.length - 1 && direction > 0) {
          return;
        }

        if (_index === 0 && direction < 0) {
          return;
        }

        if (_lookupList[_index + direction]) {
          // eslint-disable-next-line consistent-return
          return _lookupList[_index + direction][0];
        }

        return;
      }

      var lookupList = getStoriesLookupList(hash);
      var index = lookupList.indexOf(storyId); // cannot navigate beyond fist or last

      if (index === lookupList.length - 1 && direction > 0) {
        return;
      }

      if (index === 0 && direction < 0) {
        return;
      } // eslint-disable-next-line consistent-return


      return lookupList[index + direction];
    },
    updateStoryArgs: function updateStoryArgs(story, updatedArgs) {
      var storyId = story.id,
          refId = story.refId;
      fullAPI.emit(UPDATE_STORY_ARGS, {
        storyId: storyId,
        updatedArgs: updatedArgs,
        options: {
          target: refId ? "storybook-ref-".concat(refId) : 'storybook-preview-iframe'
        }
      });
    },
    resetStoryArgs: function resetStoryArgs(story, argNames) {
      var storyId = story.id,
          refId = story.refId;
      fullAPI.emit(RESET_STORY_ARGS, {
        storyId: storyId,
        argNames: argNames,
        options: {
          target: refId ? "storybook-ref-".concat(refId) : 'storybook-preview-iframe'
        }
      });
    },
    fetchStoryList: function () {
      var _fetchStoryList = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2() {
        var result, storyIndex;
        return regeneratorRuntime.wrap(function _callee2$(_context2) {
          while (1) {
            switch (_context2.prev = _context2.next) {
              case 0:
                _context2.prev = 0;
                _context2.next = 3;
                return fetch(STORY_INDEX_PATH);

              case 3:
                result = _context2.sent;

                if (!(result.status !== 200)) {
                  _context2.next = 10;
                  break;
                }

                _context2.t0 = Error;
                _context2.next = 8;
                return result.text();

              case 8:
                _context2.t1 = _context2.sent;
                throw new _context2.t0(_context2.t1);

              case 10:
                _context2.next = 12;
                return result.json();

              case 12:
                storyIndex = _context2.sent;

                if (!(storyIndex.v !== 3)) {
                  _context2.next = 16;
                  break;
                }

                logger.warn("Skipping story index with version v".concat(storyIndex.v, ", awaiting SET_STORIES."));
                return _context2.abrupt("return");

              case 16:
                _context2.next = 18;
                return fullAPI.setStoryList(storyIndex);

              case 18:
                _context2.next = 23;
                break;

              case 20:
                _context2.prev = 20;
                _context2.t2 = _context2["catch"](0);
                store.setState({
                  storiesConfigured: true,
                  storiesFailed: _context2.t2
                });

              case 23:
              case "end":
                return _context2.stop();
            }
          }
        }, _callee2, null, [[0, 20]]);
      }));

      function fetchStoryList() {
        return _fetchStoryList.apply(this, arguments);
      }

      return fetchStoryList;
    }(),
    setStoryList: function () {
      var _setStoryList = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee3(storyIndex) {
        var hash;
        return regeneratorRuntime.wrap(function _callee3$(_context3) {
          while (1) {
            switch (_context3.prev = _context3.next) {
              case 0:
                hash = transformStoryIndexToStoriesHash(storyIndex, {
                  provider: provider
                });
                _context3.next = 3;
                return store.setState({
                  storiesHash: hash,
                  storiesConfigured: true,
                  storiesFailed: null
                });

              case 3:
              case "end":
                return _context3.stop();
            }
          }
        }, _callee3);
      }));

      function setStoryList(_x3) {
        return _setStoryList.apply(this, arguments);
      }

      return setStoryList;
    }(),
    updateStory: function () {
      var _updateStory = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee4(storyId, update, ref) {
        var _store$getState8, storiesHash, _refId, _stories;

        return regeneratorRuntime.wrap(function _callee4$(_context4) {
          while (1) {
            switch (_context4.prev = _context4.next) {
              case 0:
                if (ref) {
                  _context4.next = 7;
                  break;
                }

                _store$getState8 = store.getState(), storiesHash = _store$getState8.storiesHash;
                storiesHash[storyId] = Object.assign({}, storiesHash[storyId], update);
                _context4.next = 5;
                return store.setState({
                  storiesHash: storiesHash
                });

              case 5:
                _context4.next = 11;
                break;

              case 7:
                _refId = ref.id, _stories = ref.stories;
                _stories[storyId] = Object.assign({}, _stories[storyId], update);
                _context4.next = 11;
                return fullAPI.updateRef(_refId, {
                  stories: _stories
                });

              case 11:
              case "end":
                return _context4.stop();
            }
          }
        }, _callee4);
      }));

      function updateStory(_x4, _x5, _x6) {
        return _updateStory.apply(this, arguments);
      }

      return updateStory;
    }()
  };

  var initModule = /*#__PURE__*/function () {
    var _ref3 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee5() {
      var _provider$serverChann;

      return regeneratorRuntime.wrap(function _callee5$(_context5) {
        while (1) {
          switch (_context5.prev = _context5.next) {
            case 0:
              // On initial load, the local iframe will select the first story (or other "selection specifier")
              // and emit STORY_SPECIFIED with the id. We need to ensure we respond to this change.
              fullAPI.on(STORY_SPECIFIED, function handler(_ref4) {
                var storyId = _ref4.storyId,
                    viewMode = _ref4.viewMode;

                var _getEventMetadata = getEventMetadata(this, fullAPI),
                    sourceType = _getEventMetadata.sourceType;

                if (fullAPI.isSettingsScreenActive()) return;

                if (sourceType === 'local') {
                  // Special case -- if we are already at the story being specified (i.e. the user started at a given story),
                  // we don't need to change URL. See https://github.com/storybookjs/storybook/issues/11677
                  var state = store.getState();

                  if (state.storyId !== storyId || state.viewMode !== viewMode) {
                    navigate("/".concat(viewMode, "/").concat(storyId));
                  }
                }
              });
              fullAPI.on(STORY_CHANGED, function handler() {
                var _getEventMetadata2 = getEventMetadata(this, fullAPI),
                    sourceType = _getEventMetadata2.sourceType;

                if (sourceType === 'local') {
                  var options = fullAPI.getCurrentParameter('options');

                  if (options) {
                    checkDeprecatedOptionParameters(options);
                    fullAPI.setOptions(options);
                  }
                }
              });
              fullAPI.on(STORY_PREPARED, function handler(_ref5) {
                var id = _ref5.id,
                    update = _objectWithoutProperties(_ref5, _excluded);

                var _getEventMetadata3 = getEventMetadata(this, fullAPI),
                    ref = _getEventMetadata3.ref,
                    sourceType = _getEventMetadata3.sourceType;

                fullAPI.updateStory(id, Object.assign({}, update, {
                  prepared: true
                }), ref);

                if (!ref) {
                  if (!store.getState().hasCalledSetOptions) {
                    var options = update.parameters.options;
                    checkDeprecatedOptionParameters(options);
                    fullAPI.setOptions(options);
                    store.setState({
                      hasCalledSetOptions: true
                    });
                  }
                } else {
                  fullAPI.updateRef(ref.id, {
                    ready: true
                  });
                }

                if (sourceType === 'local') {
                  var _store$getState9 = store.getState(),
                      _storyId = _store$getState9.storyId,
                      storiesHash = _store$getState9.storiesHash; // create a list of related stories to be preloaded


                  var toBePreloaded = Array.from(new Set([api.findSiblingStoryId(_storyId, storiesHash, 1, true), api.findSiblingStoryId(_storyId, storiesHash, -1, true)])).filter(Boolean);
                  fullAPI.emit(PRELOAD_STORIES, toBePreloaded);
                }
              });
              fullAPI.on(SET_STORIES, function handler(data) {
                var _getEventMetadata4 = getEventMetadata(this, fullAPI),
                    ref = _getEventMetadata4.ref;

                var stories = data.v ? denormalizeStoryParameters(data) : data.stories;

                if (!ref) {
                  if (!data.v) {
                    throw new Error('Unexpected legacy SET_STORIES event from local source');
                  }

                  fullAPI.setStories(stories);
                  var options = fullAPI.getCurrentParameter('options');
                  checkDeprecatedOptionParameters(options);
                  fullAPI.setOptions(options);
                } else {
                  fullAPI.setRef(ref.id, Object.assign({}, ref, data, {
                    stories: stories
                  }), true);
                }
              });
              fullAPI.on(SELECT_STORY, function handler(_ref6) {
                var kind = _ref6.kind,
                    story = _ref6.story,
                    storyId = _ref6.storyId,
                    rest = _objectWithoutProperties(_ref6, _excluded2);

                var _getEventMetadata5 = getEventMetadata(this, fullAPI),
                    ref = _getEventMetadata5.ref;

                if (!ref) {
                  fullAPI.selectStory(storyId || kind, story, rest);
                } else {
                  fullAPI.selectStory(storyId || kind, story, Object.assign({}, rest, {
                    ref: ref.id
                  }));
                }
              });
              fullAPI.on(STORY_ARGS_UPDATED, function handleStoryArgsUpdated(_ref7) {
                var storyId = _ref7.storyId,
                    args = _ref7.args;

                var _getEventMetadata6 = getEventMetadata(this, fullAPI),
                    ref = _getEventMetadata6.ref;

                fullAPI.updateStory(storyId, {
                  args: args
                }, ref);
              });
              fullAPI.on(CONFIG_ERROR, function handleConfigError(err) {
                store.setState({
                  storiesConfigured: true,
                  storiesFailed: err
                });
              });

              if (!(FEATURES !== null && FEATURES !== void 0 && FEATURES.storyStoreV7)) {
                _context5.next = 11;
                break;
              }

              (_provider$serverChann = provider.serverChannel) === null || _provider$serverChann === void 0 ? void 0 : _provider$serverChann.on(STORY_INDEX_INVALIDATED, function () {
                return fullAPI.fetchStoryList();
              });
              _context5.next = 11;
              return fullAPI.fetchStoryList();

            case 11:
            case "end":
              return _context5.stop();
          }
        }
      }, _callee5);
    }));

    return function initModule() {
      return _ref3.apply(this, arguments);
    };
  }();

  return {
    api: api,
    state: {
      storiesHash: {},
      storyId: initialStoryId,
      viewMode: initialViewMode,
      storiesConfigured: false,
      hasCalledSetOptions: false
    },
    init: initModule
  };
};