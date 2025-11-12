"use strict";
const globals = require('globals');
const config = require('./base');
module.exports = [
    ...config,
    {
        name: '@intlify/vue-i18n:recommended:setup',
        languageOptions: {
            ecmaVersion: 2018,
            sourceType: 'module',
            globals: globals.browser,
            parserOptions: {
                ecmaFeatures: {
                    jsx: true
                }
            }
        }
    },
    {
        name: '@intlify/vue-i18n:recommended:rules',
        rules: {
            '@intlify/vue-i18n/no-deprecated-i18n-component': 'warn',
            '@intlify/vue-i18n/no-deprecated-i18n-place-attr': 'warn',
            '@intlify/vue-i18n/no-deprecated-i18n-places-prop': 'warn',
            '@intlify/vue-i18n/no-deprecated-modulo-syntax': 'warn',
            '@intlify/vue-i18n/no-deprecated-tc': 'warn',
            '@intlify/vue-i18n/no-html-messages': 'warn',
            '@intlify/vue-i18n/no-i18n-t-path-prop': 'warn',
            '@intlify/vue-i18n/no-missing-keys': 'warn',
            '@intlify/vue-i18n/no-raw-text': 'warn',
            '@intlify/vue-i18n/no-v-html': 'warn',
            '@intlify/vue-i18n/valid-message-syntax': 'warn'
        }
    }
];
