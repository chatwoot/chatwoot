import _asyncToGenerator from "@babel/runtime/helpers/asyncToGenerator";
import _extends from "@babel/runtime/helpers/extends";
import _classCallCheck from "@babel/runtime/helpers/classCallCheck";
import _createClass from "@babel/runtime/helpers/createClass";
import _inherits from "@babel/runtime/helpers/inherits";
import _possibleConstructorReturn from "@babel/runtime/helpers/possibleConstructorReturn";
import _getPrototypeOf from "@babel/runtime/helpers/getPrototypeOf";
import _defineProperty from "@babel/runtime/helpers/defineProperty";
import _regeneratorRuntime from "@babel/runtime/regenerator";

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = _getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = _getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return _possibleConstructorReturn(this, result); }; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

import React from 'react';
import highlight from './highlight';
export default (function (options) {
  var loader = options.loader,
      isLanguageRegistered = options.isLanguageRegistered,
      registerLanguage = options.registerLanguage,
      languageLoaders = options.languageLoaders,
      noAsyncLoadingLanguages = options.noAsyncLoadingLanguages;

  var ReactAsyncHighlighter = /*#__PURE__*/function (_React$PureComponent) {
    _inherits(ReactAsyncHighlighter, _React$PureComponent);

    var _super = _createSuper(ReactAsyncHighlighter);

    function ReactAsyncHighlighter() {
      _classCallCheck(this, ReactAsyncHighlighter);

      return _super.apply(this, arguments);
    }

    _createClass(ReactAsyncHighlighter, [{
      key: "componentDidUpdate",
      value: function componentDidUpdate() {
        if (!ReactAsyncHighlighter.isRegistered(this.props.language) && languageLoaders) {
          this.loadLanguage();
        }
      }
    }, {
      key: "componentDidMount",
      value: function componentDidMount() {
        var _this = this;

        if (!ReactAsyncHighlighter.astGeneratorPromise) {
          ReactAsyncHighlighter.loadAstGenerator();
        }

        if (!ReactAsyncHighlighter.astGenerator) {
          ReactAsyncHighlighter.astGeneratorPromise.then(function () {
            _this.forceUpdate();
          });
        }

        if (!ReactAsyncHighlighter.isRegistered(this.props.language) && languageLoaders) {
          this.loadLanguage();
        }
      }
    }, {
      key: "loadLanguage",
      value: function loadLanguage() {
        var _this2 = this;

        var language = this.props.language;

        if (language === 'text') {
          return;
        }

        ReactAsyncHighlighter.loadLanguage(language).then(function () {
          return _this2.forceUpdate();
        })["catch"](function () {});
      }
    }, {
      key: "normalizeLanguage",
      value: function normalizeLanguage(language) {
        return ReactAsyncHighlighter.isSupportedLanguage(language) ? language : 'text';
      }
    }, {
      key: "render",
      value: function render() {
        return /*#__PURE__*/React.createElement(ReactAsyncHighlighter.highlightInstance, _extends({}, this.props, {
          language: this.normalizeLanguage(this.props.language),
          astGenerator: ReactAsyncHighlighter.astGenerator
        }));
      }
    }], [{
      key: "preload",
      value: function preload() {
        return ReactAsyncHighlighter.loadAstGenerator();
      }
    }, {
      key: "loadLanguage",
      value: function () {
        var _loadLanguage = _asyncToGenerator( /*#__PURE__*/_regeneratorRuntime.mark(function _callee(language) {
          var languageLoader;
          return _regeneratorRuntime.wrap(function _callee$(_context) {
            while (1) {
              switch (_context.prev = _context.next) {
                case 0:
                  languageLoader = languageLoaders[language];

                  if (!(typeof languageLoader === 'function')) {
                    _context.next = 5;
                    break;
                  }

                  return _context.abrupt("return", languageLoader(ReactAsyncHighlighter.registerLanguage));

                case 5:
                  throw new Error("Language ".concat(language, " not supported"));

                case 6:
                case "end":
                  return _context.stop();
              }
            }
          }, _callee);
        }));

        function loadLanguage(_x) {
          return _loadLanguage.apply(this, arguments);
        }

        return loadLanguage;
      }()
    }, {
      key: "isSupportedLanguage",
      value: function isSupportedLanguage(language) {
        return ReactAsyncHighlighter.isRegistered(language) || typeof languageLoaders[language] === 'function';
      }
    }, {
      key: "loadAstGenerator",
      value: function loadAstGenerator() {
        ReactAsyncHighlighter.astGeneratorPromise = loader().then(function (astGenerator) {
          ReactAsyncHighlighter.astGenerator = astGenerator;

          if (registerLanguage) {
            ReactAsyncHighlighter.languages.forEach(function (language, name) {
              return registerLanguage(astGenerator, name, language);
            });
          }
        });
        return ReactAsyncHighlighter.astGeneratorPromise;
      }
    }]);

    return ReactAsyncHighlighter;
  }(React.PureComponent);

  _defineProperty(ReactAsyncHighlighter, "astGenerator", null);

  _defineProperty(ReactAsyncHighlighter, "highlightInstance", highlight(null, {}));

  _defineProperty(ReactAsyncHighlighter, "astGeneratorPromise", null);

  _defineProperty(ReactAsyncHighlighter, "languages", new Map());

  _defineProperty(ReactAsyncHighlighter, "supportedLanguages", options.supportedLanguages || Object.keys(languageLoaders || {}));

  _defineProperty(ReactAsyncHighlighter, "isRegistered", function (language) {
    if (noAsyncLoadingLanguages) {
      return true;
    }

    if (!registerLanguage) {
      throw new Error("Current syntax highlighter doesn't support registration of languages");
    }

    if (!ReactAsyncHighlighter.astGenerator) {
      // Ast generator not available yet, but language will be registered once it is.
      return ReactAsyncHighlighter.languages.has(language);
    }

    return isLanguageRegistered(ReactAsyncHighlighter.astGenerator, language);
  });

  _defineProperty(ReactAsyncHighlighter, "registerLanguage", function (name, language) {
    if (!registerLanguage) {
      throw new Error("Current syntax highlighter doesn't support registration of languages");
    }

    if (ReactAsyncHighlighter.astGenerator) {
      return registerLanguage(ReactAsyncHighlighter.astGenerator, name, language);
    } else {
      ReactAsyncHighlighter.languages.set(name, language);
    }
  });

  return ReactAsyncHighlighter;
});