import { getOptions } from 'loader-utils';
import injectDecorator from '../abstract-syntax-tree/inject-decorator';
import { sanitizeSource } from '../abstract-syntax-tree/generate-helpers';

function readAsObject(classLoader, inputSource, mainFile) {
  const options = getOptions(classLoader) || {};
  const result = injectDecorator(inputSource, classLoader.resourcePath, Object.assign({}, options, {
    parser: options.parser || classLoader.extension
  }), classLoader.emitWarning.bind(classLoader));
  const sourceJson = sanitizeSource(result.storySource || inputSource);
  const addsMap = result.addsMap || {};
  const source = mainFile ? result.source : inputSource;
  return new Promise(resolve => resolve({
    source,
    sourceJson,
    addsMap
  }));
}

export function readStory(classLoader, inputSource) {
  return readAsObject(classLoader, inputSource, true);
}