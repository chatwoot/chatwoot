"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/es.weak-map.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.object.get-own-property-descriptor.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getSourceProps = exports.SourceState = exports.Source = void 0;

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.array.join.js");

var _react = _interopRequireWildcard(require("react"));

var _components = require("@storybook/components");

var _DocsContext = require("./DocsContext");

var _SourceContainer = require("./SourceContainer");

var _types = require("./types");

var _shared = require("../shared");

var _enhanceSource = require("./enhanceSource");

var _useStory = require("./useStory");

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

var SourceState;
exports.SourceState = SourceState;

(function (SourceState) {
  SourceState["OPEN"] = "open";
  SourceState["CLOSED"] = "closed";
  SourceState["NONE"] = "none";
})(SourceState || (exports.SourceState = SourceState = {}));

var getSourceState = function getSourceState(stories) {
  var states = stories.map(function (story) {
    var _story$parameters$doc, _story$parameters$doc2;

    return (_story$parameters$doc = story.parameters.docs) === null || _story$parameters$doc === void 0 ? void 0 : (_story$parameters$doc2 = _story$parameters$doc.source) === null || _story$parameters$doc2 === void 0 ? void 0 : _story$parameters$doc2.state;
  }).filter(Boolean);
  if (states.length === 0) return SourceState.CLOSED; // FIXME: handling multiple stories is a pain

  return states[0];
};

var getStorySource = function getStorySource(storyId, sourceContext) {
  var sources = sourceContext.sources; // source rendering is async so source is unavailable at the start of the render cycle,
  // so we fail gracefully here without warning

  return (sources === null || sources === void 0 ? void 0 : sources[storyId]) || {
    code: '',
    format: false
  };
};

var getSnippet = function getSnippet(snippet, story) {
  var _parameters$docs, _parameters$docs$sour, _parameters$docs2, _parameters$docs2$sou, _enhanced$docs, _enhanced$docs$source;

  if (!story) {
    return snippet;
  }

  var parameters = story.parameters; // eslint-disable-next-line no-underscore-dangle

  var isArgsStory = parameters.__isArgsStory;
  var type = ((_parameters$docs = parameters.docs) === null || _parameters$docs === void 0 ? void 0 : (_parameters$docs$sour = _parameters$docs.source) === null || _parameters$docs$sour === void 0 ? void 0 : _parameters$docs$sour.type) || _shared.SourceType.AUTO; // if user has hard-coded the snippet, that takes precedence

  var userCode = (_parameters$docs2 = parameters.docs) === null || _parameters$docs2 === void 0 ? void 0 : (_parameters$docs2$sou = _parameters$docs2.source) === null || _parameters$docs2$sou === void 0 ? void 0 : _parameters$docs2$sou.code;

  if (userCode !== undefined) {
    return userCode;
  } // if user has explicitly set this as dynamic, use snippet


  if (type === _shared.SourceType.DYNAMIC) {
    var _parameters$docs3, _parameters$docs3$tra;

    return ((_parameters$docs3 = parameters.docs) === null || _parameters$docs3 === void 0 ? void 0 : (_parameters$docs3$tra = _parameters$docs3.transformSource) === null || _parameters$docs3$tra === void 0 ? void 0 : _parameters$docs3$tra.call(_parameters$docs3, snippet, story)) || snippet;
  } // if this is an args story and there's a snippet


  if (type === _shared.SourceType.AUTO && snippet && isArgsStory) {
    var _parameters$docs4, _parameters$docs4$tra;

    return ((_parameters$docs4 = parameters.docs) === null || _parameters$docs4 === void 0 ? void 0 : (_parameters$docs4$tra = _parameters$docs4.transformSource) === null || _parameters$docs4$tra === void 0 ? void 0 : _parameters$docs4$tra.call(_parameters$docs4, snippet, story)) || snippet;
  } // otherwise, use the source code logic


  var enhanced = (0, _enhanceSource.enhanceSource)(story) || parameters;
  return (enhanced === null || enhanced === void 0 ? void 0 : (_enhanced$docs = enhanced.docs) === null || _enhanced$docs === void 0 ? void 0 : (_enhanced$docs$source = _enhanced$docs.source) === null || _enhanced$docs$source === void 0 ? void 0 : _enhanced$docs$source.code) || '';
};

var getSourceProps = function getSourceProps(props, docsContext, sourceContext) {
  var currentId = docsContext.id,
      storyById = docsContext.storyById;

  var _storyById = storyById(currentId),
      parameters = _storyById.parameters;

  var codeProps = props;
  var singleProps = props;
  var multiProps = props;
  var source = codeProps.code; // prefer user-specified code

  var format = codeProps.format; // prefer user-specified code

  var targetIds = multiProps.ids || [singleProps.id || currentId];
  var storyIds = targetIds.map(function (targetId) {
    return targetId === _types.CURRENT_SELECTION ? currentId : targetId;
  });
  var stories = (0, _useStory.useStories)(storyIds, docsContext);

  if (!stories.every(Boolean)) {
    return {
      error: _components.SourceError.SOURCE_UNAVAILABLE,
      state: SourceState.NONE
    };
  }

  if (!source) {
    // just take the format from the first story, given how they're all concatinated together...
    // TODO: we should consider sending an event with all the sources separately, instead of concatenating them here
    var _getStorySource = getStorySource(storyIds[0], sourceContext);

    format = _getStorySource.format;
    source = storyIds.map(function (storyId, idx) {
      var _getStorySource2 = getStorySource(storyId, sourceContext),
          storySource = _getStorySource2.code;

      var storyObj = stories[idx];
      return getSnippet(storySource, storyObj);
    }).join('\n\n');
  }

  var state = getSourceState(stories);
  var _parameters$docs5 = parameters.docs,
      docsParameters = _parameters$docs5 === void 0 ? {} : _parameters$docs5;
  var _docsParameters$sourc = docsParameters.source,
      sourceParameters = _docsParameters$sourc === void 0 ? {} : _docsParameters$sourc;
  var _sourceParameters$lan = sourceParameters.language,
      docsLanguage = _sourceParameters$lan === void 0 ? null : _sourceParameters$lan;
  return source ? {
    code: source,
    state: state,
    format: format,
    language: props.language || docsLanguage || 'jsx',
    dark: props.dark || false
  } : {
    error: _components.SourceError.SOURCE_UNAVAILABLE,
    state: state
  };
};
/**
 * Story source doc block renders source code if provided,
 * or the source for a story if `storyId` is provided, or
 * the source for the current story if nothing is provided.
 */


exports.getSourceProps = getSourceProps;

var Source = function Source(props) {
  var sourceContext = (0, _react.useContext)(_SourceContainer.SourceContext);
  var docsContext = (0, _react.useContext)(_DocsContext.DocsContext);
  var sourceProps = getSourceProps(props, docsContext, sourceContext);
  return /*#__PURE__*/_react.default.createElement(_components.Source, sourceProps);
};

exports.Source = Source;