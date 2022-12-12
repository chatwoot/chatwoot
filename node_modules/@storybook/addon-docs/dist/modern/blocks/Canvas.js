const _excluded = ["withSource", "mdxSource", "children"];

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

const getPreviewProps = (_ref, docsContext, sourceContext) => {
  let {
    withSource,
    mdxSource,
    children
  } = _ref,
      props = _objectWithoutPropertiesLoose(_ref, _excluded);

  const {
    mdxComponentAnnotations,
    mdxStoryNameToKey
  } = docsContext;
  let sourceState = withSource;
  let isLoading = false;

  if (sourceState === SourceState.NONE) {
    return {
      isLoading,
      previewProps: props
    };
  }

  if (mdxSource) {
    return {
      isLoading,
      previewProps: Object.assign({}, props, {
        withSource: getSourceProps({
          code: decodeURI(mdxSource)
        }, docsContext, sourceContext)
      })
    };
  }

  const childArray = Array.isArray(children) ? children : [children];
  const storyChildren = childArray.filter(c => c.props && (c.props.id || c.props.name));
  const targetIds = storyChildren.map(s => s.props.id || toId(mdxComponentAnnotations.id || mdxComponentAnnotations.title, storyNameFromExport(mdxStoryNameToKey[s.props.name])));
  const sourceProps = getSourceProps({
    ids: targetIds
  }, docsContext, sourceContext);
  if (!sourceState) sourceState = sourceProps.state;
  const storyIds = targetIds.map(targetId => targetId === CURRENT_SELECTION ? docsContext.id : targetId);
  const stories = useStories(storyIds, docsContext);
  isLoading = stories.some(s => !s);
  return {
    isLoading,
    previewProps: Object.assign({}, props, {
      // pass through columns etc.
      withSource: sourceProps,
      isExpanded: sourceState === SourceState.OPEN
    })
  };
};

export const Canvas = props => {
  const docsContext = useContext(DocsContext);
  const sourceContext = useContext(SourceContext);
  const {
    isLoading,
    previewProps
  } = getPreviewProps(props, docsContext, sourceContext);
  const {
    children
  } = props;
  if (isLoading) return /*#__PURE__*/React.createElement(PreviewSkeleton, null);
  return /*#__PURE__*/React.createElement(MDXProvider, {
    components: resetComponents
  }, /*#__PURE__*/React.createElement(PurePreview, previewProps, children));
};