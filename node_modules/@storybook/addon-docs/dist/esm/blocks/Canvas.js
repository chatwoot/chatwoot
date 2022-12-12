import "core-js/modules/es.object.keys.js";
import "core-js/modules/es.symbol.js";
var _excluded = ["withSource", "mdxSource", "children"];
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.array.map.js";

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import React, { useContext } from 'react';
import { MDXProvider } from '@mdx-js/react';
import { toId, storyNameFromExport } from '@storybook/csf';
import { resetComponents, Preview as PurePreview, PreviewSkeleton } from '@storybook/components';
import { DocsContext } from './DocsContext';
import { SourceContext } from './SourceContainer';
import { getSourceProps, SourceState } from './Source';
import { useStories } from './useStory';
import { CURRENT_SELECTION } from './types';
export { SourceState };

var getPreviewProps = function getPreviewProps(_ref, docsContext, sourceContext) {
  var withSource = _ref.withSource,
      mdxSource = _ref.mdxSource,
      children = _ref.children,
      props = _objectWithoutProperties(_ref, _excluded);

  var mdxComponentAnnotations = docsContext.mdxComponentAnnotations,
      mdxStoryNameToKey = docsContext.mdxStoryNameToKey;
  var sourceState = withSource;
  var isLoading = false;

  if (sourceState === SourceState.NONE) {
    return {
      isLoading: isLoading,
      previewProps: props
    };
  }

  if (mdxSource) {
    return {
      isLoading: isLoading,
      previewProps: Object.assign({}, props, {
        withSource: getSourceProps({
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
    return s.props.id || toId(mdxComponentAnnotations.id || mdxComponentAnnotations.title, storyNameFromExport(mdxStoryNameToKey[s.props.name]));
  });
  var sourceProps = getSourceProps({
    ids: targetIds
  }, docsContext, sourceContext);
  if (!sourceState) sourceState = sourceProps.state;
  var storyIds = targetIds.map(function (targetId) {
    return targetId === CURRENT_SELECTION ? docsContext.id : targetId;
  });
  var stories = useStories(storyIds, docsContext);
  isLoading = stories.some(function (s) {
    return !s;
  });
  return {
    isLoading: isLoading,
    previewProps: Object.assign({}, props, {
      // pass through columns etc.
      withSource: sourceProps,
      isExpanded: sourceState === SourceState.OPEN
    })
  };
};

export var Canvas = function Canvas(props) {
  var docsContext = useContext(DocsContext);
  var sourceContext = useContext(SourceContext);

  var _getPreviewProps = getPreviewProps(props, docsContext, sourceContext),
      isLoading = _getPreviewProps.isLoading,
      previewProps = _getPreviewProps.previewProps;

  var children = props.children;
  if (isLoading) return /*#__PURE__*/React.createElement(PreviewSkeleton, null);
  return /*#__PURE__*/React.createElement(MDXProvider, {
    components: resetComponents
  }, /*#__PURE__*/React.createElement(PurePreview, previewProps, children));
};