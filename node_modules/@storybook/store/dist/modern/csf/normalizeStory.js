import { storyNameFromExport, toId } from '@storybook/csf';
import dedent from 'ts-dedent';
import { logger } from '@storybook/client-logger';
import deprecate from 'util-deprecate';
import { normalizeInputTypes } from './normalizeInputTypes';
const deprecatedStoryAnnotation = dedent`
CSF .story annotations deprecated; annotate story functions directly:
- StoryFn.story.name => StoryFn.storyName
- StoryFn.story.(parameters|decorators) => StoryFn.(parameters|decorators)
See https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#hoisted-csf-annotations for details and codemod.
`;
const deprecatedStoryAnnotationWarning = deprecate(() => {}, deprecatedStoryAnnotation);
export function normalizeStory(key, storyAnnotations, meta) {
  let userStoryFn;
  let storyObject;

  if (typeof storyAnnotations === 'function') {
    userStoryFn = storyAnnotations;
    storyObject = storyAnnotations;
  } else {
    storyObject = storyAnnotations;
  }

  const {
    story
  } = storyObject;

  if (story) {
    logger.debug('deprecated story', story);
    deprecatedStoryAnnotationWarning();
  }

  const exportName = storyNameFromExport(key);
  const name = typeof storyObject !== 'function' && storyObject.name || storyObject.storyName || (story === null || story === void 0 ? void 0 : story.name) || exportName;
  const decorators = [...(storyObject.decorators || []), ...((story === null || story === void 0 ? void 0 : story.decorators) || [])];
  const parameters = Object.assign({}, story === null || story === void 0 ? void 0 : story.parameters, storyObject.parameters);
  const args = Object.assign({}, story === null || story === void 0 ? void 0 : story.args, storyObject.args);
  const argTypes = Object.assign({}, story === null || story === void 0 ? void 0 : story.argTypes, storyObject.argTypes);
  const loaders = [...(storyObject.loaders || []), ...((story === null || story === void 0 ? void 0 : story.loaders) || [])];
  const {
    render,
    play
  } = storyObject; // eslint-disable-next-line no-underscore-dangle

  const id = parameters.__id || toId(meta.id || meta.title, exportName);
  return Object.assign({
    id,
    name,
    decorators,
    parameters,
    args,
    argTypes: normalizeInputTypes(argTypes),
    loaders
  }, render && {
    render
  }, userStoryFn && {
    userStoryFn
  }, play && {
    play
  });
}