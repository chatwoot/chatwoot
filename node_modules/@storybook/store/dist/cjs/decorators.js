"use strict";

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.symbol.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.decorateStory = decorateStory;
exports.defaultDecorateStory = defaultDecorateStory;
exports.sanitizeStoryContextUpdate = sanitizeStoryContextUpdate;

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.object.to-string.js");

var _excluded = ["componentId", "title", "kind", "id", "name", "story", "parameters", "initialArgs", "argTypes"];

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

function decorateStory(storyFn, decorator, bindWithContext) {
  // Bind the partially decorated storyFn so that when it is called it always knows about the story context,
  // no matter what it is passed directly. This is because we cannot guarantee a decorator will
  // pass the context down to the next decorated story in the chain.
  var boundStoryFunction = bindWithContext(storyFn);
  return function (context) {
    return decorator(boundStoryFunction, context);
  };
}

/**
 * Currently StoryContextUpdates are allowed to have any key in the type.
 * However, you cannot overwrite any of the build-it "static" keys.
 *
 * @param inputContextUpdate StoryContextUpdate
 * @returns StoryContextUpdate
 */
function sanitizeStoryContextUpdate() {
  var _ref = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

  var componentId = _ref.componentId,
      title = _ref.title,
      kind = _ref.kind,
      id = _ref.id,
      name = _ref.name,
      story = _ref.story,
      parameters = _ref.parameters,
      initialArgs = _ref.initialArgs,
      argTypes = _ref.argTypes,
      update = _objectWithoutProperties(_ref, _excluded);

  return update;
}

function defaultDecorateStory(storyFn, decorators) {
  // We use a trick to avoid recreating the bound story function inside `decorateStory`.
  // Instead we pass it a context "getter", which is defined once (at "decoration time")
  // The getter reads a variable which is scoped to this call of `decorateStory`
  // (ie to this story), so there is no possibility of overlap.
  // This will break if you call the same story twice interleaved
  // (React might do it if you rendered the same story twice in the one ReactDom.render call, for instance)
  var contextStore = {};
  /**
   * When you call the story function inside a decorator, e.g.:
   *
   * ```jsx
   * <div>{storyFn({ foo: 'bar' })}</div>
   * ```
   *
   * This will override the `foo` property on the `innerContext`, which gets
   * merged in with the default context
   */

  var bindWithContext = function bindWithContext(decoratedStoryFn) {
    return function (update) {
      contextStore.value = Object.assign({}, contextStore.value, sanitizeStoryContextUpdate(update));
      return decoratedStoryFn(contextStore.value);
    };
  };

  var decoratedWithContextStore = decorators.reduce(function (story, decorator) {
    return decorateStory(story, decorator, bindWithContext);
  }, storyFn);
  return function (context) {
    contextStore.value = context;
    return decoratedWithContextStore(context); // Pass the context directly into the first decorator
  };
}