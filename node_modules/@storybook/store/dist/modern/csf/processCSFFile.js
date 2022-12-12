const _excluded = ["default", "__namedExportsOrder"];

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import { isExportStory } from '@storybook/csf';
import { logger } from '@storybook/client-logger';
import { normalizeStory } from './normalizeStory';
import { normalizeComponentAnnotations } from './normalizeComponentAnnotations';

const checkGlobals = parameters => {
  const {
    globals,
    globalTypes
  } = parameters;

  if (globals || globalTypes) {
    logger.error('Global args/argTypes can only be set globally', JSON.stringify({
      globals,
      globalTypes
    }));
  }
};

const checkStorySort = parameters => {
  const {
    options
  } = parameters;
  if (options !== null && options !== void 0 && options.storySort) logger.error('The storySort option parameter can only be set globally');
};

const checkDisallowedParameters = parameters => {
  if (!parameters) {
    return;
  }

  checkGlobals(parameters);
  checkStorySort(parameters);
}; // Given the raw exports of a CSF file, check and normalize it.


export function processCSFFile(moduleExports, importPath, title) {
  const {
    default: defaultExport
  } = moduleExports,
        namedExports = _objectWithoutPropertiesLoose(moduleExports, _excluded);

  const meta = normalizeComponentAnnotations(defaultExport, title, importPath);
  checkDisallowedParameters(meta.parameters);
  const csfFile = {
    meta,
    stories: {}
  };
  Object.keys(namedExports).forEach(key => {
    if (isExportStory(key, meta)) {
      const storyMeta = normalizeStory(key, namedExports[key], meta);
      checkDisallowedParameters(storyMeta.parameters);
      csfFile.stories[storyMeta.id] = storyMeta;
    }
  });
  return csfFile;
}