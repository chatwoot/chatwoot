const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
    baseUrl: 'http://localhost:8080',
    fixturesFolder: 'spec/cypress/fixtures',
    downloadsFolder: 'spec/cypress/downloads',
    fileServerFolder: 'spec/cypress/public',
    screenshotsFolder: 'spec/cypress/screenshots',
    videosFolder: 'spec/cypress/videos',
  },
});
