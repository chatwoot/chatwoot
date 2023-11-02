const { defineConfig } = require('cypress');

module.exports = defineConfig({
  defaultCommandTimeout: 10000,
  viewportWidth: 1250,
  viewportHeight: 800,
  e2e: {
    baseUrl: 'http://localhost:5050',
  },
});
