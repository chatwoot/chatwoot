import React, { createContext, useEffect, useState } from 'react';
import deepEqual from 'fast-deep-equal';
import { addons } from '@storybook/addons';
import { SNIPPET_RENDERED } from '../shared';
export const SourceContext = /*#__PURE__*/createContext({
  sources: {}
});
export const SourceContainer = ({
  children
}) => {
  const [sources, setSources] = useState({});
  const channel = addons.getChannel();
  useEffect(() => {
    const handleSnippetRendered = (id, newSource, format = false) => {
      // optimization: if the source is the same, ignore the incoming event
      if (sources[id] && sources[id].code === newSource) {
        return;
      }

      setSources(current => {
        const newSources = Object.assign({}, current, {
          [id]: {
            code: newSource,
            format
          }
        });

        if (!deepEqual(current, newSources)) {
          return newSources;
        }

        return current;
      });
    };

    channel.on(SNIPPET_RENDERED, handleSnippetRendered);
    return () => channel.off(SNIPPET_RENDERED, handleSnippetRendered);
  }, []);
  return /*#__PURE__*/React.createElement(SourceContext.Provider, {
    value: {
      sources
    }
  }, children);
};