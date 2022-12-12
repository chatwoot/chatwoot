function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

import "core-js/modules/es.function.name.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.promise.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.regexp.exec.js";
import React, { useContext, useRef, useEffect, useState } from 'react';
import { MDXProvider } from '@mdx-js/react';
import global from 'global';
import { resetComponents, Story as PureStory, StorySkeleton } from '@storybook/components';
import { toId, storyNameFromExport } from '@storybook/csf';
import { addons } from '@storybook/addons';
import Events from '@storybook/core-events';
import { CURRENT_SELECTION } from './types';
import { DocsContext } from './DocsContext';
import { useStory } from './useStory';
export var storyBlockIdFromId = function storyBlockIdFromId(storyId) {
  return "story--".concat(storyId);
};
export var lookupStoryId = function lookupStoryId(storyName, _ref) {
  var mdxStoryNameToKey = _ref.mdxStoryNameToKey,
      mdxComponentAnnotations = _ref.mdxComponentAnnotations;
  return toId(mdxComponentAnnotations.id || mdxComponentAnnotations.title, storyNameFromExport(mdxStoryNameToKey[storyName]));
};
export var getStoryId = function getStoryId(props, context) {
  var _ref2 = props,
      id = _ref2.id;
  var _ref3 = props,
      name = _ref3.name;
  var inputId = id === CURRENT_SELECTION ? context.id : id;
  return inputId || lookupStoryId(name, context);
};
export var getStoryProps = function getStoryProps(_ref4, story, context, onStoryFnCalled) {
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

function makeGate() {
  var open;
  var gate = new Promise(function (r) {
    open = r;
  });
  return [gate, open];
}

var Story = function Story(props) {
  var context = useContext(DocsContext);
  var channel = addons.getChannel();
  var storyRef = useRef();
  var storyId = getStoryId(props, context);
  var story = useStory(storyId, context);

  var _useState = useState(true),
      _useState2 = _slicedToArray(_useState, 2),
      showLoader = _useState2[0],
      setShowLoader = _useState2[1];

  useEffect(function () {
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

  useEffect(onRendered);

  if (!story) {
    return /*#__PURE__*/React.createElement(StorySkeleton, null);
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
    if (!(global !== null && global !== void 0 && (_global$FEATURES = global.FEATURES) !== null && _global$FEATURES !== void 0 && _global$FEATURES.modernInlineRender)) {
      // We need to wait for two things before we can consider the story rendered:
      //  (a) React's `useEffect` hook needs to fire. This is needed for React stories, as
      //      decorators of the form `<A><B/></A>` will not actually execute `B` in the first
      //      call to the story function.
      //  (b) The story function needs to actually have been called.
      //      Certain frameworks (i.e.angular) don't actually render the component in the very first
      //      React render cycle, so we need to wait for the framework to actually do that
      Promise.all([storyFnRan, rendered]).then(function () {
        channel.emit(Events.STORY_RENDERED, storyId);
      });
    } else {
      // We do this so React doesn't complain when we replace the span in a secondary render
      var htmlContents = "<span></span>"; // FIXME: height/style/etc. lifted from PureStory

      var height = storyProps.height;
      return /*#__PURE__*/React.createElement("div", {
        id: storyBlockIdFromId(story.id)
      }, /*#__PURE__*/React.createElement(MDXProvider, {
        components: resetComponents
      }, height ? /*#__PURE__*/React.createElement("style", null, "#story--".concat(story.id, " { min-height: ").concat(height, "; transform: translateZ(0); overflow: auto }")) : null, showLoader && /*#__PURE__*/React.createElement(StorySkeleton, null), /*#__PURE__*/React.createElement("div", {
        ref: storyRef,
        "data-name": story.name,
        dangerouslySetInnerHTML: {
          __html: htmlContents
        }
      })));
    }
  }

  return /*#__PURE__*/React.createElement("div", {
    id: storyBlockIdFromId(story.id)
  }, /*#__PURE__*/React.createElement(MDXProvider, {
    components: resetComponents
  }, /*#__PURE__*/React.createElement(PureStory, storyProps)));
};

Story.defaultProps = {
  children: null,
  name: null
};
export { Story };