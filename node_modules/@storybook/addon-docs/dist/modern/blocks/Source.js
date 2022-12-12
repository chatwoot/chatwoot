import React, { useContext } from 'react';
import { Source as PureSource, SourceError } from '@storybook/components';
import { DocsContext } from './DocsContext';
import { SourceContext } from './SourceContainer';
import { CURRENT_SELECTION } from './types';
import { SourceType } from '../shared';
import { enhanceSource } from './enhanceSource';
import { useStories } from './useStory';
export let SourceState;

(function (SourceState) {
  SourceState["OPEN"] = "open";
  SourceState["CLOSED"] = "closed";
  SourceState["NONE"] = "none";
})(SourceState || (SourceState = {}));

const getSourceState = stories => {
  const states = stories.map(story => {
    var _story$parameters$doc, _story$parameters$doc2;

    return (_story$parameters$doc = story.parameters.docs) === null || _story$parameters$doc === void 0 ? void 0 : (_story$parameters$doc2 = _story$parameters$doc.source) === null || _story$parameters$doc2 === void 0 ? void 0 : _story$parameters$doc2.state;
  }).filter(Boolean);
  if (states.length === 0) return SourceState.CLOSED; // FIXME: handling multiple stories is a pain

  return states[0];
};

const getStorySource = (storyId, sourceContext) => {
  const {
    sources
  } = sourceContext; // source rendering is async so source is unavailable at the start of the render cycle,
  // so we fail gracefully here without warning

  return (sources === null || sources === void 0 ? void 0 : sources[storyId]) || {
    code: '',
    format: false
  };
};

const getSnippet = (snippet, story) => {
  var _parameters$docs, _parameters$docs$sour, _parameters$docs2, _parameters$docs2$sou, _enhanced$docs, _enhanced$docs$source;

  if (!story) {
    return snippet;
  }

  const {
    parameters
  } = story; // eslint-disable-next-line no-underscore-dangle

  const isArgsStory = parameters.__isArgsStory;
  const type = ((_parameters$docs = parameters.docs) === null || _parameters$docs === void 0 ? void 0 : (_parameters$docs$sour = _parameters$docs.source) === null || _parameters$docs$sour === void 0 ? void 0 : _parameters$docs$sour.type) || SourceType.AUTO; // if user has hard-coded the snippet, that takes precedence

  const userCode = (_parameters$docs2 = parameters.docs) === null || _parameters$docs2 === void 0 ? void 0 : (_parameters$docs2$sou = _parameters$docs2.source) === null || _parameters$docs2$sou === void 0 ? void 0 : _parameters$docs2$sou.code;

  if (userCode !== undefined) {
    return userCode;
  } // if user has explicitly set this as dynamic, use snippet


  if (type === SourceType.DYNAMIC) {
    var _parameters$docs3, _parameters$docs3$tra;

    return ((_parameters$docs3 = parameters.docs) === null || _parameters$docs3 === void 0 ? void 0 : (_parameters$docs3$tra = _parameters$docs3.transformSource) === null || _parameters$docs3$tra === void 0 ? void 0 : _parameters$docs3$tra.call(_parameters$docs3, snippet, story)) || snippet;
  } // if this is an args story and there's a snippet


  if (type === SourceType.AUTO && snippet && isArgsStory) {
    var _parameters$docs4, _parameters$docs4$tra;

    return ((_parameters$docs4 = parameters.docs) === null || _parameters$docs4 === void 0 ? void 0 : (_parameters$docs4$tra = _parameters$docs4.transformSource) === null || _parameters$docs4$tra === void 0 ? void 0 : _parameters$docs4$tra.call(_parameters$docs4, snippet, story)) || snippet;
  } // otherwise, use the source code logic


  const enhanced = enhanceSource(story) || parameters;
  return (enhanced === null || enhanced === void 0 ? void 0 : (_enhanced$docs = enhanced.docs) === null || _enhanced$docs === void 0 ? void 0 : (_enhanced$docs$source = _enhanced$docs.source) === null || _enhanced$docs$source === void 0 ? void 0 : _enhanced$docs$source.code) || '';
};

export const getSourceProps = (props, docsContext, sourceContext) => {
  const {
    id: currentId,
    storyById
  } = docsContext;
  const {
    parameters
  } = storyById(currentId);
  const codeProps = props;
  const singleProps = props;
  const multiProps = props;
  let source = codeProps.code; // prefer user-specified code

  let {
    format
  } = codeProps; // prefer user-specified code

  const targetIds = multiProps.ids || [singleProps.id || currentId];
  const storyIds = targetIds.map(targetId => targetId === CURRENT_SELECTION ? currentId : targetId);
  const stories = useStories(storyIds, docsContext);

  if (!stories.every(Boolean)) {
    return {
      error: SourceError.SOURCE_UNAVAILABLE,
      state: SourceState.NONE
    };
  }

  if (!source) {
    // just take the format from the first story, given how they're all concatinated together...
    // TODO: we should consider sending an event with all the sources separately, instead of concatenating them here
    ({
      format
    } = getStorySource(storyIds[0], sourceContext));
    source = storyIds.map((storyId, idx) => {
      const {
        code: storySource
      } = getStorySource(storyId, sourceContext);
      const storyObj = stories[idx];
      return getSnippet(storySource, storyObj);
    }).join('\n\n');
  }

  const state = getSourceState(stories);
  const {
    docs: docsParameters = {}
  } = parameters;
  const {
    source: sourceParameters = {}
  } = docsParameters;
  const {
    language: docsLanguage = null
  } = sourceParameters;
  return source ? {
    code: source,
    state,
    format,
    language: props.language || docsLanguage || 'jsx',
    dark: props.dark || false
  } : {
    error: SourceError.SOURCE_UNAVAILABLE,
    state
  };
};
/**
 * Story source doc block renders source code if provided,
 * or the source for a story if `storyId` is provided, or
 * the source for the current story if nothing is provided.
 */

export const Source = props => {
  const sourceContext = useContext(SourceContext);
  const docsContext = useContext(DocsContext);
  const sourceProps = getSourceProps(props, docsContext, sourceContext);
  return /*#__PURE__*/React.createElement(PureSource, sourceProps);
};