import highlight from './highlight';
import defaultStyle from './styles/hljs/default-style';
import lowlight from 'lowlight';
import supportedLanguages from './languages/hljs/supported-languages';
var highlighter = highlight(lowlight, defaultStyle);
highlighter.supportedLanguages = supportedLanguages;
export default highlighter;