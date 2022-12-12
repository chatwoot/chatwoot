import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.array.includes.js";
import "core-js/modules/es.object.keys.js";
import defaultOptions from './default-options';
import getParser from './parsers';
import { generateSourceWithDecorators, generateSourceWithoutDecorators, generateStorySource, generateStoriesLocationsMap, generateSourcesInExportedParameters, generateSourcesInStoryParameters } from './generate-helpers';

function extendOptions(source, comments, filepath, options) {
  return Object.assign({}, defaultOptions, options, {
    source: source,
    comments: comments,
    filepath: filepath
  });
}

function inject(source, filepath) {
  var options = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : {};
  var log = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : function (message) {};
  var _options$injectDecora = options.injectDecorator,
      injectDecorator = _options$injectDecora === void 0 ? true : _options$injectDecora,
      _options$injectStoryP = options.injectStoryParameters,
      injectStoryParameters = _options$injectStoryP === void 0 ? false : _options$injectStoryP;
  var obviouslyNotCode = ['md', 'txt', 'json'].includes(options.parser);
  var parser = null;

  try {
    parser = getParser(options.parser || filepath);
  } catch (e) {
    log(new Error("(not fatal, only impacting storysource) Could not load a parser (".concat(e, ")")));
  }

  if (obviouslyNotCode || !parser) {
    return {
      source: source,
      storySource: {},
      addsMap: {},
      changed: false
    };
  }

  var ast = parser.parse(source);

  var _ref = injectDecorator === true ? generateSourceWithDecorators(source, ast) : generateSourceWithoutDecorators(source, ast),
      changed = _ref.changed,
      cleanedSource = _ref.source,
      comments = _ref.comments,
      exportTokenFound = _ref.exportTokenFound;

  var storySource = generateStorySource(extendOptions(source, comments, filepath, options));
  var newAst = parser.parse(storySource);
  var addsMap = generateStoriesLocationsMap(newAst, []);
  var newSource = cleanedSource;

  if (exportTokenFound) {
    var cleanedSourceAst = parser.parse(cleanedSource);

    if (injectStoryParameters) {
      newSource = generateSourcesInStoryParameters(cleanedSource, cleanedSourceAst, {
        source: storySource,
        locationsMap: addsMap
      });
    } else {
      newSource = generateSourcesInExportedParameters(cleanedSource, cleanedSourceAst, {
        source: storySource,
        locationsMap: addsMap
      });
    }
  }

  if (!changed && Object.keys(addsMap || {}).length === 0) {
    return {
      source: newSource,
      storySource: storySource,
      addsMap: {},
      changed: changed
    };
  }

  return {
    source: newSource,
    storySource: storySource,
    addsMap: addsMap,
    changed: changed
  };
}

export default inject;