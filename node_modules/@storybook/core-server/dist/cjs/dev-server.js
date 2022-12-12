"use strict";

require("core-js/modules/es.symbol.description.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.router = exports.DEBOUNCE = void 0;
exports.storybookDevServer = storybookDevServer;

require("core-js/modules/es.promise.js");

var _express = _interopRequireWildcard(require("express"));

var _compression = _interopRequireDefault(require("compression"));

var _coreCommon = require("@storybook/core-common");

var _telemetry = require("@storybook/telemetry");

var _middleware = require("./utils/middleware");

var _serverAddress = require("./utils/server-address");

var _serverInit = require("./utils/server-init");

var _serverStatics = require("./utils/server-statics");

var _storiesJson = require("./utils/stories-json");

var _metadata = require("./utils/metadata");

var _getServerChannel = require("./utils/get-server-channel");

var _openInBrowser = require("./utils/open-in-browser");

var _getPreviewBuilder = require("./utils/get-preview-builder");

var _getManagerBuilder = require("./utils/get-manager-builder");

var _StoryIndexGenerator = require("./utils/StoryIndexGenerator");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function (nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || typeof obj !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

// @ts-ignore
var router = new _express.Router();
exports.router = router;
var DEBOUNCE = 100;
exports.DEBOUNCE = DEBOUNCE;

async function storybookDevServer(options) {
  var startTime = process.hrtime();
  var app = (0, _express.default)();
  var server = await (0, _serverInit.getServer)(app, options);
  var serverChannel = (0, _getServerChannel.getServerChannel)(server);
  var features = await options.presets.apply('features');
  var core = await options.presets.apply('core'); // try get index generator, if failed, send telemetry without storyCount, then rethrow the error

  var initializedStoryIndexGenerator = Promise.resolve(undefined);

  if (features !== null && features !== void 0 && features.buildStoriesJson || features !== null && features !== void 0 && features.storyStoreV7) {
    try {
      var workingDir = process.cwd();
      var directories = {
        configDir: options.configDir,
        workingDir: workingDir
      };
      var normalizedStories = (0, _coreCommon.normalizeStories)(await options.presets.apply('stories'), directories);
      var generator = new _StoryIndexGenerator.StoryIndexGenerator(normalizedStories, _objectSpread(_objectSpread({}, directories), {}, {
        workingDir: workingDir,
        storiesV2Compatibility: !(features !== null && features !== void 0 && features.breakingChangesV7) && !(features !== null && features !== void 0 && features.storyStoreV7),
        storyStoreV7: features === null || features === void 0 ? void 0 : features.storyStoreV7
      }));
      initializedStoryIndexGenerator = generator.initialize().then(function () {
        return generator;
      });
      (0, _storiesJson.useStoriesJson)({
        router: router,
        initializedStoryIndexGenerator: initializedStoryIndexGenerator,
        normalizedStories: normalizedStories,
        serverChannel: serverChannel,
        workingDir: workingDir
      });
    } catch (err) {
      if (!(core !== null && core !== void 0 && core.disableTelemetry)) {
        (0, _telemetry.telemetry)('start');
      }

      throw err;
    }
  }

  if (!(core !== null && core !== void 0 && core.disableTelemetry)) {
    initializedStoryIndexGenerator.then(async function (generator) {
      if (!generator) {
        return;
      }

      var storyIndex = await generator.getIndex();
      var payload = storyIndex ? {
        storyIndex: {
          storyCount: Object.keys(storyIndex.stories).length,
          version: storyIndex.v
        }
      } : undefined;
      (0, _telemetry.telemetry)('start', payload, {
        configDir: options.configDir
      });
    });
  }

  if (!(core !== null && core !== void 0 && core.disableProjectJson)) {
    (0, _metadata.useStorybookMetadata)(router, options.configDir);
  }

  app.use((0, _compression.default)({
    level: 1
  }));

  if (typeof options.extendServer === 'function') {
    options.extendServer(server);
  }

  app.use(function (req, res, next) {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept'); // These headers are required to enable SharedArrayBuffer
    // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer

    next();
  });

  if (core !== null && core !== void 0 && core.crossOriginIsolated) {
    app.use(function (req, res, next) {
      // These headers are required to enable SharedArrayBuffer
      // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer
      res.header('Cross-Origin-Opener-Policy', 'same-origin');
      res.header('Cross-Origin-Embedder-Policy', 'require-corp');
      next();
    });
  } // User's own static files


  await (0, _serverStatics.useStatics)(router, options);
  (0, _middleware.getMiddleware)(options.configDir)(router);
  app.use(router);
  var port = options.port,
      host = options.host;
  var proto = options.https ? 'https' : 'http';

  var _getServerAddresses = (0, _serverAddress.getServerAddresses)(port, host, proto),
      address = _getServerAddresses.address,
      networkAddress = _getServerAddresses.networkAddress;

  await new Promise(function (resolve, reject) {
    // FIXME: Following line doesn't match TypeScript signature at all 🤔
    // @ts-ignore
    server.listen({
      port: port,
      host: host
    }, function (error) {
      return error ? reject(error) : resolve();
    });
  });
  var previewBuilder = await (0, _getPreviewBuilder.getPreviewBuilder)(options.configDir);
  var managerBuilder = await (0, _getManagerBuilder.getManagerBuilder)(options.configDir);

  if (options.debugWebpack) {
    (0, _coreCommon.logConfig)('Preview webpack config', await previewBuilder.getConfig(options));
    (0, _coreCommon.logConfig)('Manager webpack config', await managerBuilder.getConfig(options));
  }

  var preview = options.ignorePreview ? Promise.resolve() : previewBuilder.start({
    startTime: startTime,
    options: options,
    router: router,
    server: server
  });
  var manager = managerBuilder.start({
    startTime: startTime,
    options: options,
    router: router,
    server: server
  });

  var _await$Promise$all = await Promise.all([preview.catch(async function (err) {
    await managerBuilder.bail();
    throw err;
  }), manager // TODO #13083 Restore this when compiling the preview is fast enough
  // .then((result) => {
  //   if (!options.ci && !options.smokeTest) openInBrowser(address);
  //   return result;
  // })
  .catch(async function (err) {
    await previewBuilder.bail();
    throw err;
  })]),
      _await$Promise$all2 = _slicedToArray(_await$Promise$all, 2),
      previewResult = _await$Promise$all2[0],
      managerResult = _await$Promise$all2[1]; // TODO #13083 Remove this when compiling the preview is fast enough


  if (!options.ci && !options.smokeTest && options.open) {
    (0, _openInBrowser.openInBrowser)(host ? networkAddress : address);
  }

  return {
    previewResult: previewResult,
    managerResult: managerResult,
    address: address,
    networkAddress: networkAddress
  };
}