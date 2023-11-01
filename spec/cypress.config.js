const { defineConfig } = require('cypress');

module.exports = defineConfig({
  defaultCommandTimeout: 10000,
  viewportWidth: 1250,
  viewportHeight: 800,
  e2e: {
    // We've imported your old cypress plugins here.
    // You may want to clean this up later by importing these.
    setupNodeEvents(on, config) {
      // eslint-disable-next-line
      return require('./cypress/plugins/index.js')(on, config);
    },
    baseUrl: 'http://localhost:5050',
  },
});
