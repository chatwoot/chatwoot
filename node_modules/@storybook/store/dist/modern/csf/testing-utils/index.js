const _excluded = ["default", "__esModule", "__namedExportsOrder"];
import "core-js/modules/es.array.reduce.js";

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import { isExportStory } from '@storybook/csf';
import { composeConfigs } from '../composeConfigs';
import { prepareStory } from '../prepareStory';
import { normalizeStory } from '../normalizeStory';
import { HooksContext } from '../../hooks';
import { normalizeComponentAnnotations } from '../normalizeComponentAnnotations';
import { getValuesFromArgTypes } from '../getValuesFromArgTypes';
import { normalizeProjectAnnotations } from '../normalizeProjectAnnotations';
export * from './types';
let GLOBAL_STORYBOOK_PROJECT_ANNOTATIONS = {};
export function setProjectAnnotations(projectAnnotations) {
  GLOBAL_STORYBOOK_PROJECT_ANNOTATIONS = Array.isArray(projectAnnotations) ? composeConfigs(projectAnnotations) : projectAnnotations;
}
export function composeStory(storyAnnotations, componentAnnotations, projectAnnotations = GLOBAL_STORYBOOK_PROJECT_ANNOTATIONS, defaultConfig = {}, exportsName) {
  var _componentAnnotations, _storyAnnotations$sto;

  if (storyAnnotations === undefined) {
    throw new Error('Expected a story but received undefined.');
  } // @TODO: Support auto title
  // eslint-disable-next-line no-param-reassign


  componentAnnotations.title = (_componentAnnotations = componentAnnotations.title) !== null && _componentAnnotations !== void 0 ? _componentAnnotations : 'ComposedStory';
  const normalizedComponentAnnotations = normalizeComponentAnnotations(componentAnnotations);
  const storyName = exportsName || storyAnnotations.storyName || ((_storyAnnotations$sto = storyAnnotations.story) === null || _storyAnnotations$sto === void 0 ? void 0 : _storyAnnotations$sto.name) || storyAnnotations.name;
  const normalizedStory = normalizeStory(storyName, storyAnnotations, normalizedComponentAnnotations);
  const normalizedProjectAnnotations = normalizeProjectAnnotations(Object.assign({}, projectAnnotations, defaultConfig));
  const story = prepareStory(normalizedStory, normalizedComponentAnnotations, normalizedProjectAnnotations);
  const defaultGlobals = getValuesFromArgTypes(projectAnnotations.globalTypes);

  const composedStory = extraArgs => {
    const context = Object.assign({}, story, {
      hooks: new HooksContext(),
      globals: defaultGlobals,
      args: Object.assign({}, story.initialArgs, extraArgs)
    });
    return story.unboundStoryFn(context);
  };

  composedStory.storyName = storyName;
  composedStory.args = story.initialArgs;
  composedStory.play = story.playFunction;
  composedStory.parameters = story.parameters;
  return composedStory;
}
export function composeStories(storiesImport, globalConfig, composeStoryFn) {
  const {
    default: meta
  } = storiesImport,
        stories = _objectWithoutPropertiesLoose(storiesImport, _excluded);

  const composedStories = Object.entries(stories).reduce((storiesMap, [exportsName, story]) => {
    if (!isExportStory(exportsName, meta)) {
      return storiesMap;
    }

    const result = Object.assign(storiesMap, {
      [exportsName]: composeStoryFn(story, meta, globalConfig, exportsName)
    });
    return result;
  }, {});
  return composedStories;
}