import "core-js/modules/es.regexp.exec.js";
import jsParser from './parser-js';
import tsParser from './parser-ts';
import flowParser from './parser-flow';

function getParser(type) {
  if (type === 'javascript' || /\.jsx?/.test(type) || !type) {
    return jsParser;
  }

  if (type === 'typescript' || /\.tsx?/.test(type)) {
    return tsParser;
  }

  if (type === 'flow') {
    return flowParser;
  }

  throw new Error("Parser of type \"".concat(type, "\" is not supported"));
}

export default getParser;