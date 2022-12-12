"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.DEBOUNCE = void 0;
exports.extractStoriesJson = extractStoriesJson;
exports.useStoriesJson = useStoriesJson;

require("core-js/modules/es.promise.js");

var _fsExtra = _interopRequireDefault(require("fs-extra"));

var _lodash = require("lodash");

var _coreEvents = require("@storybook/core-events");

var _watchStorySpecifiers = require("./watch-story-specifiers");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var DEBOUNCE = 100;
exports.DEBOUNCE = DEBOUNCE;

async function extractStoriesJson(outputFile, initializedStoryIndexGenerator) {
  var generator = await initializedStoryIndexGenerator;
  var storyIndex = await generator.getIndex();
  await _fsExtra.default.writeJson(outputFile, storyIndex);
}

function useStoriesJson({
  router: router,
  initializedStoryIndexGenerator: initializedStoryIndexGenerator,
  workingDir = process.cwd(),
  serverChannel: serverChannel,
  normalizedStories: normalizedStories
}) {
  var maybeInvalidate = (0, _lodash.debounce)(function () {
    return serverChannel.emit(_coreEvents.STORY_INDEX_INVALIDATED);
  }, DEBOUNCE, {
    leading: true
  });
  (0, _watchStorySpecifiers.watchStorySpecifiers)(normalizedStories, {
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