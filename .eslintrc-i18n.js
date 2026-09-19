module.exports = {
  extends: ['plugin:@intlify/vue-i18n/base'],
  settings: {
    'vue-i18n': {
      localeDir: './app/javascript/*/i18n/**/*.json',
      messageSyntaxVersion: '^9.0.0',
    },
  },
  rules: {
    // Report locale catalogs also contain numeric option IDs.
    '@intlify/vue-i18n/valid-message-syntax': [
      'error',
      { allowNotString: true },
    ],
  },
};
