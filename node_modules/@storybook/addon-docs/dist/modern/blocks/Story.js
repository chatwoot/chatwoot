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
export const storyBlockIdFromId = storyId => `story--${storyId}`;
export const lookupStoryId = (storyName, {
  mdxStoryNameToKey,
  mdxComponentAnnotations
}) => toId(mdxComponentAnnotations.id || mdxComponentAnnotations.title, storyNameFromExport(mdxStoryNameToKey[storyName]));
export const getStoryId = (props, context) => {
  const {
    id
  } = props;
  const {
    name
  } = props;
  const inputId = id === CURRENT_SELECTION ? context.id : id;
  return inputId || lookupStoryId(name, context);
};
export const getStoryProps = ({
  height,
  inline
}, story, context, onStoryFnCalled) => {
  const {
    name: storyName,
    parameters
  } = story;
  const {
    docs = {}
  } = parameters;

  if (docs.disable) {
    return null;
  } // prefer block props, then story parameters defined by the framework-specific settings and optionally overridden by users


  const {
    inlineStories = false,
    iframeHeight = 100,
    prepareForInline
  } = docs;
  const storyIsInline = typeof inline === 'boolean' ? inline : inlineStories;

  if (storyIsInline && !prepareForInline) {
    throw new Error(`Story '${storyName}' is set to render inline, but no 'prepareForInline' function is implemented in your docs configuration!`);
  }

  const boundStoryFn = () => {
    const storyResult = story.unboundStoryFn(Object.assign({}, context.getStoryContext(story), {
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
    parameters,
    storyFn: () => prepareForInline(boundStoryFn, context.getStoryContext(story))
  });
};

function makeGate() {
  let open;
  const gate = new Promise(r => {
    open = r;
  });
  return [gate, open];
}

const Story = props => {
  const context = useContext(DocsContext);
  const channel = addons.getChannel();
  const storyRef = useRef();
  const storyId = getStoryId(props, context);
  const story = useStory(storyId, context);
  const [showLoader, setShowLoader] = useState(true);
  useEffect(() => {
    let cleanup;

    if (story && storyRef.current) {
      const element = storyRef.current;
      cleanup = context.renderStoryToElement(story, element);
      setShowLoader(false);
    }

    return () => cleanup && cleanup();
  }, [story]);
  const [storyFnRan, onStoryFnRan] = makeGate();
  const [rendered, onRendered] = makeGate();
  useEffect(onRendered);

  if (!story) {
    return /*#__PURE__*/React.createElement(StorySkeleton, null);
  }

  const storyProps = getStoryProps(props, story, context, onStoryFnRan);

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
      Promise.all([storyFnRan, rendered]).then(() => {
        channel.emit(Events.STORY_RENDERED, storyId);
      });
    } else {
      // We do this so React doesn't complain when we replace the span in a secondary render
      const htmlContents = `<span></span>`; // FIXME: height/style/etc. lifted from PureStory

      const {
        height
      } = storyProps;
      return /*#__PURE__*/React.createElement("div", {
        id: storyBlockIdFromId(story.id)
      }, /*#__PURE__*/React.createElement(MDXProvider, {
        components: resetComponents
      }, height ? /*#__PURE__*/React.createElement("style", null, `#story--${story.id} { min-height: ${height}; transform: translateZ(0); overflow: auto }`) : null, showLoader && /*#__PURE__*/React.createElement(StorySkeleton, null), /*#__PURE__*/React.createElement("div", {
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