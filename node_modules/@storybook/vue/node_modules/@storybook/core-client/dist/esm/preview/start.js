function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.regexp.exec.js";
import global from 'global';
import deprecate from 'util-deprecate';
import { ClientApi } from '@storybook/client-api';
import { PreviewWeb } from '@storybook/preview-web';
import createChannel from '@storybook/channel-postmessage';
import { addons } from '@storybook/addons';
import Events from '@storybook/core-events';
import { executeLoadableForChanges } from './executeLoadable';
var globalWindow = global.window,
    FEATURES = global.FEATURES;
var configureDeprecationWarning = deprecate(function () {}, "`configure()` is deprecated and will be removed in Storybook 7.0. \nPlease use the `stories` field of `main.js` to load stories.\nRead more at https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-configure");

var removedApi = function removedApi(name) {
  return function () {
    throw new Error("@storybook/client-api:".concat(name, " was removed in storyStoreV7."));
  };
};

export function start(renderToDOM) {
  var _ref = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {},
      decorateStory = _ref.decorateStory,
      render = _ref.render;

  if (globalWindow) {
    // To enable user code to detect if it is running in Storybook
    globalWindow.IS_STORYBOOK = true;
  }

  if (FEATURES !== null && FEATURES !== void 0 && FEATURES.storyStoreV7) {
    return {
      forceReRender: removedApi('forceReRender'),
      getStorybook: removedApi('getStorybook'),
      configure: removedApi('configure'),
      clientApi: {
        addDecorator: removedApi('clientApi.addDecorator'),
        addParameters: removedApi('clientApi.addParameters'),
        clearDecorators: removedApi('clientApi.clearDecorators'),
        addLoader: removedApi('clientApi.addLoader'),
        setAddon: removedApi('clientApi.setAddon'),
        getStorybook: removedApi('clientApi.getStorybook'),
        storiesOf: removedApi('clientApi.storiesOf'),
        raw: removedApi('raw')
      }
    };
  }

  var channel = createChannel({
    page: 'preview'
  });
  addons.setChannel(channel);
  var clientApi = new ClientApi();
  var preview = new PreviewWeb();
  var initialized = false;

  var importFn = function importFn(path) {
    return clientApi.importFn(path);
  };

  function onStoriesChanged() {
    var storyIndex = clientApi.getStoryIndex();
    preview.onStoriesChanged({
      storyIndex: storyIndex,
      importFn: importFn
    });
  } // These two bits are a bit ugly, but due to dependencies, `ClientApi` cannot have
  // direct reference to `PreviewWeb`, so we need to patch in bits


  clientApi.onImportFnChanged = onStoriesChanged;
  clientApi.storyStore = preview.storyStore;

  if (globalWindow) {
    globalWindow.__STORYBOOK_CLIENT_API__ = clientApi;
    globalWindow.__STORYBOOK_ADDONS_CHANNEL__ = channel; // eslint-disable-next-line no-underscore-dangle

    globalWindow.__STORYBOOK_PREVIEW__ = preview;
    globalWindow.__STORYBOOK_STORY_STORE__ = preview.storyStore;
  }

  return {
    forceReRender: function forceReRender() {
      return channel.emit(Events.FORCE_RE_RENDER);
    },
    getStorybook: function getStorybook() {
      return [];
    },
    raw: function raw() {},
    clientApi: clientApi,
    // This gets called each time the user calls configure (i.e. once per HMR)
    // The first time, it constructs the preview, subsequently it updates it
    configure: function configure(framework, loadable, m) {
      var showDeprecationWarning = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : true;

      if (showDeprecationWarning) {
        configureDeprecationWarning();
      }

      clientApi.addParameters({
        framework: framework
      }); // We need to run the `executeLoadableForChanges` function *inside* the `getProjectAnnotations
      // function in case it throws. So we also need to process its output there also

      var getProjectAnnotations = function getProjectAnnotations() {
        var _executeLoadableForCh = executeLoadableForChanges(loadable, m),
            added = _executeLoadableForCh.added,
            removed = _executeLoadableForCh.removed;

        Array.from(added.entries()).forEach(function (_ref2) {
          var _ref3 = _slicedToArray(_ref2, 2),
              fileName = _ref3[0],
              fileExports = _ref3[1];

          return clientApi.facade.addStoriesFromExports(fileName, fileExports);
        });
        Array.from(removed.entries()).forEach(function (_ref4) {
          var _ref5 = _slicedToArray(_ref4, 1),
              fileName = _ref5[0];

          return clientApi.facade.clearFilenameExports(fileName);
        });
        return Object.assign({
          render: render
        }, clientApi.facade.projectAnnotations, {
          renderToDOM: renderToDOM,
          applyDecorators: decorateStory
        });
      };

      if (!initialized) {
        preview.initialize({
          getStoryIndex: function getStoryIndex() {
            return clientApi.getStoryIndex();
          },
          importFn: importFn,
          getProjectAnnotations: getProjectAnnotations
        });
        initialized = true;
      } else {
        // TODO -- why don't we care about the new annotations?
        getProjectAnnotations();
        onStoriesChanged();
      }
    }
  };
}