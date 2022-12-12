import highlight from './highlight';
import refractor from 'refractor/core';
var SyntaxHighlighter = highlight(refractor, {});

SyntaxHighlighter.registerLanguage = function (_, language) {
  return refractor.register(language);
};

SyntaxHighlighter.alias = function (name, aliases) {
  return refractor.alias(name, aliases);
};

export default SyntaxHighlighter;