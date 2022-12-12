import createAsyncLoadingHighlighter from './async-syntax-highlighter';
import supportedLanguages from './languages/prism/supported-languages';
export default createAsyncLoadingHighlighter({
  loader: function loader() {
    return import(
    /* webpackChunkName:"react-syntax-highlighter/refractor-import" */
    'refractor').then(function (module) {
      // Webpack 3 returns module.exports as default as module, but webpack 4 returns module.exports as module.default
      return module["default"] || module;
    });
  },
  noAsyncLoadingLanguages: true,
  supportedLanguages: supportedLanguages
});