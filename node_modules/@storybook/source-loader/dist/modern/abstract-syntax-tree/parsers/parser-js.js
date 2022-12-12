import parseJs from 'prettier/parser-babel';

function parse(source) {
  try {
    return parseJs.parsers.babel.parse(source);
  } catch (error1) {
    try {
      return JSON.stringify(source);
    } catch (error) {
      throw error1;
    }
  }
}

function format(source) {
  return parseJs.parsers.babel.format(source);
}

export default {
  parse,
  format
};