/*
 * IMPORTANT!
 * This file has been automatically generated,
 * in order to update its content execute "npm run update"
 */
const globals = require('globals')
module.exports = [
  {
    name: 'vue/base/setup',
    plugins: {
      get vue() {
        return require('../../index')
      }
    },
    languageOptions: {
      sourceType: 'module',
      globals: globals.browser
    }
  },
  {
    name: 'vue/base/setup-for-vue',
    files: ['*.vue', '**/*.vue'],
    plugins: {
      get vue() {
        return require('../../index')
      }
    },
    languageOptions: {
      parser: require('vue-eslint-parser'),
      sourceType: 'module',
      globals: globals.browser
    },
    rules: {
      'vue/comment-directive': 'error',
      'vue/jsx-uses-vars': 'error'
    },
    processor: 'vue/vue'
  }
]
