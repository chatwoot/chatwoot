import "core-js/modules/es.symbol.js";
var _excluded = ["default", "__namedExportsOrder"];
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.object.keys.js";

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import { isExportStory } from '@storybook/csf';
import { logger } from '@storybook/client-logger';
import { normalizeStory } from './normalizeStory';
import { normalizeComponentAnnotations } from './normalizeComponentAnnotations';

var checkGlobals = function checkGlobals(parameters) {
  var globals = parameters.globals,
      globalTypes = parameters.globalTypes;

  if (globals || globalTypes) {
    logger.error('Global args/argTypes can only be set globally', JSON.stringify({
      globals: globals,
      globalTypes: globalTypes
    }));
  }
};

var checkStorySort = function checkStorySort(parameters) {
  var options = parameters.options;
  if (options !== null && options !== void 0 && options.storySort) logger.error('The storySort option parameter can only be set globally');
};

var checkDisallowedParameters = function checkDisallowedParameters(parameters) {
  if (!parameters) {
    return;
  }

  checkGlobals(parameters);
  checkStorySort(parameters);
}; // Given the raw exports of a CSF file, check and normalize it.


export function processCSFFile(moduleExports, importPath, title) {
  var defaultExport = moduleExports.default,
      __namedExportsOrder = moduleExports.__namedExportsOrder,
      namedExports = _objectWithoutProperties(moduleExports, _excluded);

  var meta = normalizeComponentAnnotations(defaultExport, title, importPath);
  checkDisallowedParameters(meta.parameters);
  var csfFile = {
    meta: meta,
    stories: {}
  };
  Object.keys(namedExports).forEach(function (key) {
    if (isExportStory(key, meta)) {
      var storyMeta = normalizeStory(key, namedExports[key], meta);
      checkDisallowedParameters(storyMeta.parameters);
      csfFile.stories[storyMeta.id] = storyMeta;
    }
  });
  return csfFile;
}