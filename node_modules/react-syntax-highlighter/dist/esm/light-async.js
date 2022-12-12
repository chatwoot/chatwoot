import createAsyncLoadingHighlighter from './async-syntax-highlighter';
import languageLoaders from './async-languages/hljs';
import checkForListedLanguage from './checkForListedLanguage';
export default createAsyncLoadingHighlighter({
  loader: function loader() {
    return import(
    /* webpackChunkName:"react-syntax-highlighter/lowlight-import" */
    'lowlight/lib/core').then(function (module) {
      // Webpack 3 returns module.exports as default as module, but webpack 4 returns module.exports as module.default
      return module["default"] || module;
    });
  },
  isLanguageRegistered: function isLanguageRegistered(instance, language) {
    return !!checkForListedLanguage(instance, language);
  },
  languageLoaders: languageLoaders,
  registerLanguage: function registerLanguage(instance, name, language) {
    return instance.registerLanguage(name, language);
  }
});