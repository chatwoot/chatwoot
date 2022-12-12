import parseFlow from 'prettier/parser-flow';

function parse(source) {
  return parseFlow.parsers.flow.parse(source);
}

function format(source) {
  return parseFlow.parsers.flow.format(source);
}

export default {
  parse,
  format
};