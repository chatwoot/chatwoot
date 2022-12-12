"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/es.weak-map.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.object.get-own-property-descriptor.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.Canvas = void 0;
Object.defineProperty(exports, "SourceState", {
  enumerable: true,
  get: function get() {
    return _Source.SourceState;
  }
});

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.array.map.js");

var _react = _interopRequireWildcard(require("react"));

var _react2 = require("@mdx-js/react");

var _csf = require("@storybook/csf");

var _components = require("@storybook/components");

var _DocsContext = require("./DocsContext");

var _SourceContainer = require("./SourceContainer");

var _Source = require("./Source");

var _useStory = require("./useStory");

var _types = require("./types");

var _excluded = ["withSource", "mdxSource", "children"];

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

var getPreviewProps = function getPreviewProps(_ref, docsContext, sourceContext) {
  var withSource = _ref.withSource,
      mdxSource = _ref.mdxSource,
      children = _ref.children,
      props = _objectWithoutProperties(_ref, _excluded);

  var mdxComponentAnnotations = docsContext.mdxComponentAnnotations,
      mdxStoryNameToKey = docsContext.mdxStoryNameToKey;
  var sourceState = withSource;
  var isLoading = false;

  if (sourceState === _Source.SourceState.NONE) {
    return {
      isLoading: isLoading,
      previewProps: props
    };
  }

  if (mdxSource) {
    return {
      isLoading: isLoading,
      previewProps: Object.assign({}, props, {
        withSource: (0, _Source.getSourceProps)({
          code: decodeURI(mdxSource)
        }, docsContext, sourceContext)
      })
    };
  }

  var childArray = Array.isArray(children) ? children : [children];
  var storyChildren = childArray.filter(function (c) {
    return c.props && (c.props.id || c.props.name);
  });
  var targetIds = storyChildren.map(function (s) {
    return s.props.id || (0, _csf.toId)(mdxComponentAnnotations.id || mdxComponentAnnotations.title, (0, _csf.storyNameFromExport)(mdxStoryNameToKey[s.props.name]));
  });
  var sourceProps = (0, _Source.getSourceProps)({
    ids: targetIds
  }, docsContext, sourceContext);
  if (!sourceState) sourceState = sourceProps.state;
  var storyIds = targetIds.map(function (targetId) {
    return targetId === _types.CURRENT_SELECTION ? docsContext.id : targetId;
  });
  var stories = (0, _useStory.useStories)(storyIds, docsContext);
  isLoading = stories.some(function (s) {
    return !s;
  });
  return {
    isLoading: isLoading,
    previewProps: Object.assign({}, props, {
      // pass through columns etc.
      withSource: sourceProps,
      isExpanded: sourceState === _Source.SourceState.OPEN
    })
  };
};

var Canvas = function Canvas(props) {
  var docsContext = (0, _react.useContext)(_DocsContext.DocsContext);
  var sourceContext = (0, _react.useContext)(_SourceContainer.SourceContext);

  var _getPreviewProps = getPreviewProps(props, docsContext, sourceContext),
      isLoading = _getPreviewProps.isLoading,
      previewProps = _getPreviewProps.previewProps;

  var children = props.children;
  if (isLoading) return /*#__PURE__*/_react.default.createElement(_components.PreviewSkeleton, null);
  return /*#__PURE__*/_react.default.createElement(_react2.MDXProvider, {
    components: _components.resetComponents
  }, /*#__PURE__*/_react.default.createElement(_components.Preview, previewProps, children));
};

exports.Canvas = Canvas;