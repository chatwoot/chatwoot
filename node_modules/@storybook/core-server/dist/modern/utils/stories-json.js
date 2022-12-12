import "core-js/modules/es.promise.js";
import fs from 'fs-extra';
import { debounce } from 'lodash';
import { STORY_INDEX_INVALIDATED } from '@storybook/core-events';
import { watchStorySpecifiers } from './watch-story-specifiers';
export var DEBOUNCE = 100;
export async function extractStoriesJson(outputFile, initializedStoryIndexGenerator) {
  var generator = await initializedStoryIndexGenerator;
  var storyIndex = await generator.getIndex();
  await fs.writeJson(outputFile, storyIndex);
}
export function useStoriesJson({
  router: router,
  initializedStoryIndexGenerator: initializedStoryIndexGenerator,
  workingDir = process.cwd(),
  serverChannel: serverChannel,
  normalizedStories: normalizedStories
}) {
  var maybeInvalidate = debounce(function () {
    return serverChannel.emit(STORY_INDEX_INVALIDATED);
  }, DEBOUNCE, {
    leading: true
  });
  watchStorySpecifiers(normalizedStories, {
    workingDir: workingDir
  }, async function (specifier, path, removed) {
    var generator = await initializedStoryIndexGenerator;
    generator.invalidate(specifier, path, removed);
    maybeInvalidate();
  });
  router.use('/stories.json', async function (req, res) {
    try {
      var generator = await initializedStoryIndexGenerator;
      var index = await generator.getIndex();
      res.header('Content-Type', 'application/json');
      res.send(JSON.stringify(index));
    } catch (err) {
      res.status(500);
      res.send(err.message);
    }
  });
}