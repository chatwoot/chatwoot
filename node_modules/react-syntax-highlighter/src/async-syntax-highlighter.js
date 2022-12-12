import React from 'react';
import highlight from './highlight';

export default options => {
  const {
    loader,
    isLanguageRegistered,
    registerLanguage,
    languageLoaders,
    noAsyncLoadingLanguages
  } = options;

  class ReactAsyncHighlighter extends React.PureComponent {
    static astGenerator = null;
    static highlightInstance = highlight(null, {});
    static astGeneratorPromise = null;
    static languages = new Map();
    static supportedLanguages =
      options.supportedLanguages || Object.keys(languageLoaders || {});

    static preload() {
      return ReactAsyncHighlighter.loadAstGenerator();
    }

    static async loadLanguage(language) {
      const languageLoader = languageLoaders[language];

      if (typeof languageLoader === 'function') {
        return languageLoader(ReactAsyncHighlighter.registerLanguage);
      } else {
        throw new Error(`Language ${language} not supported`);
      }
    }

    static isSupportedLanguage(language) {
      return (
        ReactAsyncHighlighter.isRegistered(language) ||
        typeof languageLoaders[language] === 'function'
      );
    }

    static isRegistered = language => {
      if (noAsyncLoadingLanguages) {
        return true;
      }

      if (!registerLanguage) {
        throw new Error(
          "Current syntax highlighter doesn't support registration of languages"
        );
      }

      if (!ReactAsyncHighlighter.astGenerator) {
        // Ast generator not available yet, but language will be registered once it is.
        return ReactAsyncHighlighter.languages.has(language);
      }

      return isLanguageRegistered(ReactAsyncHighlighter.astGenerator, language);
    };

    static registerLanguage = (name, language) => {
      if (!registerLanguage) {
        throw new Error(
          "Current syntax highlighter doesn't support registration of languages"
        );
      }

      if (ReactAsyncHighlighter.astGenerator) {
        return registerLanguage(
          ReactAsyncHighlighter.astGenerator,
          name,
          language
        );
      } else {
        ReactAsyncHighlighter.languages.set(name, language);
      }
    };

    static loadAstGenerator() {
      ReactAsyncHighlighter.astGeneratorPromise = loader().then(
        astGenerator => {
          ReactAsyncHighlighter.astGenerator = astGenerator;

          if (registerLanguage) {
            ReactAsyncHighlighter.languages.forEach((language, name) =>
              registerLanguage(astGenerator, name, language)
            );
          }
        }
      );

      return ReactAsyncHighlighter.astGeneratorPromise;
    }

    componentDidUpdate() {
      if (
        !ReactAsyncHighlighter.isRegistered(this.props.language) &&
        languageLoaders
      ) {
        this.loadLanguage();
      }
    }

    componentDidMount() {
      if (!ReactAsyncHighlighter.astGeneratorPromise) {
        ReactAsyncHighlighter.loadAstGenerator();
      }

      if (!ReactAsyncHighlighter.astGenerator) {
        ReactAsyncHighlighter.astGeneratorPromise.then(() => {
          this.forceUpdate();
        });
      }

      if (
        !ReactAsyncHighlighter.isRegistered(this.props.language) &&
        languageLoaders
      ) {
        this.loadLanguage();
      }
    }

    loadLanguage() {
      const { language } = this.props;

      if (language === 'text') {
        return;
      }

      ReactAsyncHighlighter.loadLanguage(language)
        .then(() => {
          return this.forceUpdate();
        })
        .catch(() => {});
    }

    normalizeLanguage(language) {
      return ReactAsyncHighlighter.isSupportedLanguage(language)
        ? language
        : 'text';
    }

    render() {
      return (
        <ReactAsyncHighlighter.highlightInstance
          {...this.props}
          language={this.normalizeLanguage(this.props.language)}
          astGenerator={ReactAsyncHighlighter.astGenerator}
        />
      );
    }
  }

  return ReactAsyncHighlighter;
};
