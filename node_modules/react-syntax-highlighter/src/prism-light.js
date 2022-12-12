import highlight from './highlight';
import refractor from 'refractor/core';

const SyntaxHighlighter = highlight(refractor, {});
SyntaxHighlighter.registerLanguage = (_, language) =>
  refractor.register(language);

SyntaxHighlighter.alias = (name, aliases) => refractor.alias(name, aliases);

export default SyntaxHighlighter;
