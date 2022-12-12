import createAsyncLoadingHighlighter from './async-syntax-highlighter';
import languageLoaders from './async-languages/prism';
export default createAsyncLoadingHighlighter({
  loader: function loader() {
    return import(
    /* webpackChunkName:"react-syntax-highlighter/refractor-core-import" */
    'refractor/core').then(function (module) {
      // Webpack 3 returns module.exports as default as module, but webpack 4 returns module.exports as module.default
      return module["default"] || module;
    });
  },
  isLanguageRegistered: function isLanguageRegistered(instance, language) {
    return instance.registered(language);
  },
  languageLoaders: languageLoaders,
  registerLanguage: function registerLanguage(instance, name, language) {
    return instance.register(language);
  }
});