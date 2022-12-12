import { combineParameters } from '@storybook/store'; // ============================================================
// START @storybook/source-loader/extract-source
//
// This code duplicated because tree-shaking isn't working.
// It's not DRY, but source-loader is on the chopping block for
// the next version of addon-docs, so it's not the worst sin.
// ============================================================

/**
 * given a location, extract the text from the full source
 */
function extractSource(location, lines) {
  const {
    startBody: start,
    endBody: end
  } = location;

  if (start.line === end.line && lines[start.line - 1] !== undefined) {
    return lines[start.line - 1].substring(start.col, end.col);
  } // NOTE: storysource locations are 1-based not 0-based!


  const startLine = lines[start.line - 1];
  const endLine = lines[end.line - 1];

  if (startLine === undefined || endLine === undefined) {
    return null;
  }

  return [startLine.substring(start.col), ...lines.slice(start.line, end.line - 1), endLine.substring(0, end.col)].join('\n');
} // ============================================================
// END @storybook/source-loader/extract-source
// ============================================================


/**
 * Replaces full story id name like: story-kind--story-name -> story-name
 * @param id
 */
const storyIdToSanitizedStoryName = id => id.replace(/^.*?--/, '');

const extract = (targetId, {
  source,
  locationsMap
}) => {
  if (!locationsMap) {
    return source;
  }

  const sanitizedStoryName = storyIdToSanitizedStoryName(targetId);
  const location = locationsMap[sanitizedStoryName];

  if (!location) {
    return source;
  }

  const lines = source.split('\n');
  return extractSource(location, lines);
};

export const enhanceSource = story => {
  var _docs$source;

  const {
    id,
    parameters
  } = story;
  const {
    storySource,
    docs = {}
  } = parameters;
  const {
    transformSource
  } = docs; // no input or user has manually overridden the output

  if (!(storySource !== null && storySource !== void 0 && storySource.source) || (_docs$source = docs.source) !== null && _docs$source !== void 0 && _docs$source.code) {
    return null;
  }

  const input = extract(id, storySource);
  const code = transformSource ? transformSource(input, story) : input;
  return {
    docs: combineParameters(docs, {
      source: {
        code
      }
    })
  };
};