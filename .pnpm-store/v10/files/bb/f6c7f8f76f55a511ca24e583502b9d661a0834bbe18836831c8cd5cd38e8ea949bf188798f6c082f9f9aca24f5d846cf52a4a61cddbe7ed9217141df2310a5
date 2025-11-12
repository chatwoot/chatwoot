"use strict";
module.exports = [
    {
        name: '@intlify/vue-i18n:base:setup',
        plugins: {
            get '@intlify/vue-i18n'() {
                return require('../../index');
            }
        }
    },
    {
        name: '@intlify/vue-i18n:base:setup:json',
        files: ['*.json', '**/*.json', '*.json5', '**/*.json5'],
        languageOptions: {
            parser: require('vue-eslint-parser'),
            parserOptions: {
                parser: require('jsonc-eslint-parser')
            }
        }
    },
    {
        name: '@intlify/vue-i18n:base:setup:yaml',
        files: ['*.yaml', '**/*.yaml', '*.yml', '**/*.yml'],
        languageOptions: {
            parser: require('vue-eslint-parser'),
            parserOptions: {
                parser: require('yaml-eslint-parser')
            }
        },
        rules: {
            'no-irregular-whitespace': 'off',
            'spaced-comment': 'off'
        }
    }
];
