import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.promise.js";
import { getOptions } from 'loader-utils';
import injectDecorator from '../abstract-syntax-tree/inject-decorator';
import { sanitizeSource } from '../abstract-syntax-tree/generate-helpers';

function readAsObject(classLoader, inputSource, mainFile) {
  var options = getOptions(classLoader) || {};
  var result = injectDecorator(inputSource, classLoader.resourcePath, Object.assign({}, options, {
    parser: options.parser || classLoader.extension
  }), classLoader.emitWarning.bind(classLoader));
  var sourceJson = sanitizeSource(result.storySource || inputSource);
  var addsMap = result.addsMap || {};
  var source = mainFile ? result.source : inputSource;
  return new Promise(function (resolve) {
    return resolve({
      source: source,
      sourceJson: sourceJson,
      addsMap: addsMap
    });
  });
}

export function readStory(classLoader, inputSource) {
  return readAsObject(classLoader, inputSource, true);
}