"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.weak-map.js");

require("core-js/modules/es.object.get-own-property-descriptor.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.storyBlockIdFromId = exports.lookupStoryId = exports.getStoryProps = exports.getStoryId = exports.Story = void 0;

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.promise.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.concat.js");

var _react = _interopRequireWildcard(require("react"));

var _react2 = require("@mdx-js/react");

var _global = _interopRequireDefault(require("global"));

var _components = require("@storybook/components");

var _csf = require("@storybook/csf");

var _addons = require("@storybook/addons");

var _coreEvents = _interopRequireDefault(require("@storybook/core-events"));

var _types = require("./types");

var _DocsContext = require("./DocsContext");

var _useStory = require("./useStory");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

var storyBlockIdFromId = function storyBlockIdFromId(storyId) {
  return "story--".concat(storyId);
};

exports.storyBlockIdFromId = storyBlockIdFromId;

var lookupStoryId = function lookupStoryId(storyName, _ref) {
  var mdxStoryNameToKey = _ref.mdxStoryNameToKey,
      mdxComponentAnnotations = _ref.mdxComponentAnnotations;
  return (0, _csf.toId)(mdxComponentAnnotations.id || mdxComponentAnnotations.title, (0, _csf.storyNameFromExport)(mdxStoryNameToKey[storyName]));
};

exports.lookupStoryId = lookupStoryId;

var getStoryId = function getStoryId(props, context) {
  var _ref2 = props,
      id = _ref2.id;
  var _ref3 = props,
      name = _ref3.name;
  var inputId = id === _types.CURRENT_SELECTION ? context.id : id;
  return inputId || lookupStoryId(name, context);
};

exports.getStoryId = getStoryId;

var getStoryProps = function getStoryProps(_ref4, story, context, onStoryFnCalled) {
  var height = _ref4.height,
      inline = _ref4.inline;
  var storyName = story.name,
      parameters = story.parameters;
  var _parameters$docs = parameters.docs,
      docs = _parameters$docs === void 0 ? {} : _parameters$docs;

  if (docs.disable) {
    return null;
  } // prefer block props, then story parameters defined by the framework-specific settings and optionally overridden by users


  var _docs$inlineStories = docs.inlineStories,
      inlineStories = _docs$inlineStories === void 0 ? false : _docs$inlineStories,
      _docs$iframeHeight = docs.iframeHeight,
      iframeHeight = _docs$iframeHeight === void 0 ? 100 : _docs$iframeHeight,
      prepareForInline = docs.prepareForInline;
  var storyIsInline = typeof inline === 'boolean' ? inline : inlineStories;

  if (storyIsInline && !prepareForInline) {
    throw new Error("Story '".concat(storyName, "' is set to render inline, but no 'prepareForInline' function is implemented in your docs configuration!"));
  }

  var boundStoryFn = function boundStoryFn() {
    var storyResult = story.unboundStoryFn(Object.assign({}, context.getStoryContext(story), {
      loaded: {},
      abortSignal: undefined,
      canvasElement: undefined
    })); // We need to wait until the bound story function has actually been called before we
    // consider the story rendered. Certain frameworks (i.e. angular) don't actually render
    // the component in the very first react render cycle, and so we can't just wait until the
    // `PureStory` component has been rendered to consider the underlying story "rendered".

    onStoryFnCalled();
    return storyResult;
  };

  return Object.assign({
    inline: storyIsInline,
    id: story.id,
    height: height || (storyIsInline ? undefined : iframeHeight),
    title: storyName
  }, storyIsInline && {
    parameters: parameters,
    storyFn: function storyFn() {
      return prepareForInline(boundStoryFn, context.getStoryContext(story));
    }
  });
};

exports.getStoryProps = getStoryProps;

function makeGate() {
  var open;
  var gate = new Promise(function (r) {
    open = r;
  });
  return [gate, open];
}

var Story = function Story(props) {
  var context = (0, _react.useContext)(_DocsContext.DocsContext);

  var channel = _addons.addons.getChannel();

  var storyRef = (0, _react.useRef)();
  var storyId = getStoryId(props, context);
  var story = (0, _useStory.useStory)(storyId, context);

  var _useState = (0, _react.useState)(true),
      _useState2 = _slicedToArray(_useState, 2),
      showLoader = _useState2[0],
      setShowLoader = _useState2[1];

  (0, _react.useEffect)(function () {
    var cleanup;

    if (story && storyRef.current) {
      var element = storyRef.current;
      cleanup = context.renderStoryToElement(story, element);
      setShowLoader(false);
    }

    return function () {
      return cleanup && cleanup();
    };
  }, [story]);

  var _makeGate = makeGate(),
      _makeGate2 = _slicedToArray(_makeGate, 2),
      storyFnRan = _makeGate2[0],
      onStoryFnRan = _makeGate2[1];

  var _makeGate3 = makeGate(),
      _makeGate4 = _slicedToArray(_makeGate3, 2),
      rendered = _makeGate4[0],
      onRendered = _makeGate4[1];

  (0, _react.useEffect)(onRendered);

  if (!story) {
    return /*#__PURE__*/_react.default.createElement(_components.StorySkeleton, null);
  }

  var storyProps = getStoryProps(props, story, context, onStoryFnRan);

  if (!storyProps) {
    return null;
  }

  if (storyProps.inline) {
    var _global$FEATURES;

    // If we are rendering a old-style inline Story via `PureStory` below, we want to emit
    // the `STORY_RENDERED` event when it renders. The modern mode below calls out to
    // `Preview.renderStoryToDom()` which itself emits the event.
    if (!(_global.default !== null && _global.default !== void 0 && (_global$FEATURES = _global.default.FEATURES) !== null && _global$FEATURES !== void 0 && _global$FEATURES.modernInlineRender)) {
      // We need to wait for two things before we can consider the story rendered:
      //  (a) React's `useEffect` hook needs to fire. This is needed for React stories, as
      //      decorators of the form `<A><B/></A>` will not actually execute `B` in the first
      //      call to the story function.
      //  (b) The story function needs to actually have been called.
      //      Certain frameworks (i.e.angular) don't actually render the component in the very first
      //      React render cycle, so we need to wait for the framework to actually do that
      Promise.all([storyFnRan, rendered]).then(function () {
        channel.emit(_coreEvents.default.STORY_RENDERED, storyId);
      });
    } else {
      // We do this so React doesn't complain when we replace the span in a secondary render
      var htmlContents = "<span></span>"; // FIXME: height/style/etc. lifted from PureStory

      var height = storyProps.height;
      return /*#__PURE__*/_react.default.createElement("div", {
        id: storyBlockIdFromId(story.id)
      }, /*#__PURE__*/_react.default.createElement(_react2.MDXProvider, {
        components: _components.resetComponents
      }, height ? /*#__PURE__*/_react.default.createElement("style", null, "#story--".concat(story.id, " { min-height: ").concat(height, "; transform: translateZ(0); overflow: auto }")) : null, showLoader && /*#__PURE__*/_react.default.createElement(_components.StorySkeleton, null), /*#__PURE__*/_react.default.createElement("div", {
        ref: storyRef,
        "data-name": story.name,
        dangerouslySetInnerHTML: {
          __html: htmlContents
        }
      })));
    }
  }

  return /*#__PURE__*/_react.default.createElement("div", {
    id: storyBlockIdFromId(story.id)
  }, /*#__PURE__*/_react.default.createElement(_react2.MDXProvider, {
    components: _components.resetComponents
  }, /*#__PURE__*/_react.default.createElement(_components.Story, storyProps)));
};

exports.Story = Story;
Story.defaultProps = {
  children: null,
  name: null
};