import highlight from './highlight';
import defaultStyle from './styles/prism/prism';
import refractor from 'refractor';
import supportedLanguages from './languages/prism/supported-languages';
var highlighter = highlight(refractor, defaultStyle);
highlighter.supportedLanguages = supportedLanguages;
export default highlighter;