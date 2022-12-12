/*!
 * wavesurfer.js 6.1.0 (2022-03-31)
 * https://wavesurfer-js.org
 * @license BSD-3-Clause
 */
(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory();
	else if(typeof define === 'function' && define.amd)
		define("WaveSurfer", [], factory);
	else if(typeof exports === 'object')
		exports["WaveSurfer"] = factory();
	else
		root["WaveSurfer"] = root["WaveSurfer"] || {}, root["WaveSurfer"]["html-init"] = factory();
})(self, function() {
return /******/ (() => { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ "./src/html-init.js":
/*!**************************!*\
  !*** ./src/html-init.js ***!
  \**************************/
/***/ ((module, exports, __webpack_require__) => {

"use strict";


Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports["default"] = void 0;

var _loadScript = _interopRequireDefault(__webpack_require__(/*! load-script */ "./node_modules/load-script/index.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

/**
 * @typedef {Object} InitParams
 * @property {WavesurferParams} [defaults={backend: 'MediaElement,
 * mediaControls: true}] The default wavesurfer initialisation parameters
 * @property {string|NodeList} containers='wavesurfer' Selector or NodeList of
 * elements to attach instances to
 * @property {string}
 * pluginCdnTemplate='//localhost:8080/dist/plugin/wavesurfer.[name].js' URL
 * template for the dynamic loading of plugins
 * @property {function} loadPlugin If set overwrites the default request function,
 * can be used to inject plugins differently.
 */

/**
 * The HTML initialisation API is not part of the main library bundle file and
 * must be additionally included.
 *
 * The API attaches wavesurfer instances to all `<wavesurfer>` (can be
 * customised), parsing their `data-` attributes to construct an options object
 * for initialisation. Among other things it can dynamically load plugin code.
 *
 * The automatic initialisation can be prevented by setting the
 * `window.WS_StopAutoInit` flag to true. The `html-init[.min].js` file exports
 * the `Init` class, which can be called manually.
 *
 * Site-wide defaults can be added by setting `window.WS_InitOptions`.
 *
 * @example
 * <!-- with minimap and timeline plugin -->
 * <wavesurfer
 *   data-url="../media/demo.wav"
 *   data-plugins="minimap,timeline"
 *   data-minimap-height="30"
 *   data-minimap-wave-color="#ddd"
 *   data-minimap-progress-color="#999"
 *   data-timeline-font-size="13px"
 *   data-timeline-container="#timeline"
 * >
 * </wavesurfer>
 * <div id="timeline"></div>
 *
 * <!-- with regions plugin -->
 * <wavesurfer
 *   data-url="../media/demo.wav"
 *   data-plugins="regions"
 *   data-regions-regions='[{"start": 1,"end": 3,"color": "hsla(400, 100%, 30%, 0.5)"}]'
 * >
 * </wavesurfer>
 */
var Init = /*#__PURE__*/function () {
  /**
   * Instantiate Init class and initialize elements
   *
   * This is done automatically if `window` is defined and
   * `window.WS_StopAutoInit` is not set to true
   *
   * @param {WaveSurfer} WaveSurfer The WaveSurfer library object
   * @param {InitParams} params initialisation options
   */
  function Init(WaveSurfer) {
    var params = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};

    _classCallCheck(this, Init);

    if (!WaveSurfer) {
      throw new Error('WaveSurfer is not available!');
    }
    /**
     * cache WaveSurfer
     * @private
     */


    this.WaveSurfer = WaveSurfer;
    /**
     * build parameters, cache them in _params so minified builds are smaller
     * @private
     */

    var _params = this.params = Object.assign({}, {
      // wavesurfer parameter defaults so by default the audio player is
      // usable with native media element controls
      defaults: {
        backend: 'MediaElement',
        mediaControls: true
      },
      // containers to instantiate on, can be selector string or NodeList
      containers: 'wavesurfer',
      // @TODO insert plugin CDN URIs
      pluginCdnTemplate: '//localhost:8080/dist/plugin/wavesurfer.[name].js',
      // loadPlugin function can be overridden to inject plugin definition
      // objects, this default function uses load-script to load a plugin
      // and pass it to a callback
      loadPlugin: function loadPlugin(name, cb) {
        var src = _params.pluginCdnTemplate.replace('[name]', name);

        (0, _loadScript.default)(src, {
          async: false
        }, function (err, plugin) {
          if (err) {
            // eslint-disable-next-line no-console
            return console.error("WaveSurfer plugin ".concat(name, " not found at ").concat(src));
          }

          cb(window.WaveSurfer[name]);
        });
      }
    }, params);
    /**
     * The nodes that should have instances attached to them
     * @type {NodeList}
     */


    this.containers = typeof _params.containers == 'string' ? document.querySelectorAll(_params.containers) : _params.containers;
    /** @private */

    this.pluginCache = {};
    /**
     * An array of wavesurfer instances
     * @type {Object[]}
     */

    this.instances = [];
    this.initAllEls();
  }
  /**
   * Initialize all container elements
   */


  _createClass(Init, [{
    key: "initAllEls",
    value: function initAllEls() {
      var _this = this;

      // iterate over all the container elements
      Array.prototype.forEach.call(this.containers, function (el) {
        // load the plugins as an array of plugin names
        var plugins = el.dataset.plugins ? el.dataset.plugins.split(',') : []; // no plugins to be loaded, just render

        if (!plugins.length) {
          return _this.initEl(el);
        } // … or: iterate over all the plugins


        plugins.forEach(function (name, i) {
          // plugin is not cached already, load it
          if (!_this.pluginCache[name]) {
            _this.params.loadPlugin(name, function (lib) {
              _this.pluginCache[name] = lib; // plugins were all loaded, render the element

              if (i + 1 === plugins.length) {
                _this.initEl(el, plugins);
              }
            });
          } else if (i === plugins.length) {
            // plugin was cached and this plugin was the last
            _this.initEl(el, plugins);
          }
        });
      });
    }
    /**
     * Initialize a single container element and add to `this.instances`
     *
     * @param  {HTMLElement} el The container to instantiate wavesurfer to
     * @param  {PluginDefinition[]} plugins An Array of plugin names to initialize with
     * @return {Object} Wavesurfer instance
     */

  }, {
    key: "initEl",
    value: function initEl(el) {
      var _this2 = this;

      var plugins = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : [];
      var jsonRegex = /^[[|{]/; // initialize plugins with the correct options

      var initialisedPlugins = plugins.map(function (plugin) {
        var options = {}; // the regex to find this plugin attributes

        var attrNameRegex = new RegExp('^' + plugin);
        var attrName; // iterate over all the data attributes and find ones for this
        // plugin

        for (attrName in el.dataset) {
          var regexResult = attrNameRegex.exec(attrName);

          if (regexResult) {
            var attr = el.dataset[attrName]; // if the string begins with a [ or a { parse it as JSON

            var prop = jsonRegex.test(attr) ? JSON.parse(attr) : attr; // this removes the plugin prefix and changes the first letter
            // of the resulting string to lower case to follow the naming
            // convention of ws params

            var unprefixedOptionName = attrName.slice(plugin.length, plugin.length + 1).toLowerCase() + attrName.slice(plugin.length + 1);
            options[unprefixedOptionName] = prop;
          }
        }

        return _this2.pluginCache[plugin].create(options);
      }); // build parameter object for this container

      var params = Object.assign({
        container: el
      }, this.params.defaults, el.dataset, {
        plugins: initialisedPlugins
      }); // @TODO make nicer

      el.style.display = 'block'; // initialize wavesurfer, load audio (with peaks if provided)

      var instance = this.WaveSurfer.create(params);
      var peaks = params.peaks ? JSON.parse(params.peaks) : undefined;
      instance.load(params.url, peaks); // push this instance into the instances cache

      this.instances.push(instance);
      return instance;
    }
  }]);

  return Init;
}(); // if window object exists and window.WS_StopAutoInit is not true


if ((typeof window === "undefined" ? "undefined" : _typeof(window)) === 'object' && !window.WS_StopAutoInit) {
  // call init when document is ready, apply any custom default settings
  // in window.WS_InitOptions
  if (document.readyState === 'complete') {
    window.WaveSurferInit = new Init(window.WaveSurfer, window.WS_InitOptions);
  } else {
    window.addEventListener('load', function () {
      window.WaveSurferInit = new Init(window.WaveSurfer, window.WS_InitOptions);
    });
  }
} // export init for manual usage


var _default = Init;
exports["default"] = _default;
module.exports = exports.default;

/***/ }),

/***/ "./node_modules/load-script/index.js":
/*!*******************************************!*\
  !*** ./node_modules/load-script/index.js ***!
  \*******************************************/
/***/ ((module) => {


module.exports = function load (src, opts, cb) {
  var head = document.head || document.getElementsByTagName('head')[0]
  var script = document.createElement('script')

  if (typeof opts === 'function') {
    cb = opts
    opts = {}
  }

  opts = opts || {}
  cb = cb || function() {}

  script.type = opts.type || 'text/javascript'
  script.charset = opts.charset || 'utf8';
  script.async = 'async' in opts ? !!opts.async : true
  script.src = src

  if (opts.attrs) {
    setAttributes(script, opts.attrs)
  }

  if (opts.text) {
    script.text = '' + opts.text
  }

  var onend = 'onload' in script ? stdOnEnd : ieOnEnd
  onend(script, cb)

  // some good legacy browsers (firefox) fail the 'in' detection above
  // so as a fallback we always set onload
  // old IE will ignore this and new IE will set onload
  if (!script.onload) {
    stdOnEnd(script, cb);
  }

  head.appendChild(script)
}

function setAttributes(script, attrs) {
  for (var attr in attrs) {
    script.setAttribute(attr, attrs[attr]);
  }
}

function stdOnEnd (script, cb) {
  script.onload = function () {
    this.onerror = this.onload = null
    cb(null, script)
  }
  script.onerror = function () {
    // this.onload = null here is necessary
    // because even IE9 works not like others
    this.onerror = this.onload = null
    cb(new Error('Failed to load ' + this.src), script)
  }
}

function ieOnEnd (script, cb) {
  script.onreadystatechange = function () {
    if (this.readyState != 'complete' && this.readyState != 'loaded') return
    this.onreadystatechange = null
    cb(null, script) // there is no way to catch loading errors in IE8
  }
}


/***/ })

/******/ 	});
/************************************************************************/
/******/ 	// The module cache
/******/ 	var __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		var cachedModule = __webpack_module_cache__[moduleId];
/******/ 		if (cachedModule !== undefined) {
/******/ 			return cachedModule.exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = __webpack_module_cache__[moduleId] = {
/******/ 			// no module.id needed
/******/ 			// no module.loaded needed
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId](module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
/******/ 	
/******/ 	// startup
/******/ 	// Load entry module and return exports
/******/ 	// This entry module is referenced by other modules so it can't be inlined
/******/ 	var __webpack_exports__ = __webpack_require__("./src/html-init.js");
/******/ 	
/******/ 	return __webpack_exports__;
/******/ })()
;
});
//# sourceMappingURL=wavesurfer-html-init.js.map