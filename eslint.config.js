const js = require('@eslint/js');
const pluginVue = require('eslint-plugin-vue');
const pluginVueI18n = require('@intlify/eslint-plugin-vue-i18n');
const prettierRecommended = require('eslint-plugin-prettier/recommended');
const globals = require('globals');

const vitestGlobals = {
  describe: 'readonly',
  it: 'readonly',
  test: 'readonly',
  expect: 'readonly',
  beforeEach: 'readonly',
  afterEach: 'readonly',
  beforeAll: 'readonly',
  afterAll: 'readonly',
  vi: 'readonly',
  vitest: 'readonly',
  suite: 'readonly',
};

module.exports = [
  { ignores: ['node_modules/**', 'public/**', 'vendor/**'] },

  js.configs.recommended,
  ...pluginVue.configs['flat/recommended'],
  ...pluginVueI18n.configs['flat/recommended'],
  prettierRecommended,

  {
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        ...globals.browser,
        ...globals.node,
        bus: 'writable',
        vi: 'readonly',
      },
    },
    settings: {
      'vue-i18n': {
        localeDir: './app/javascript/*/i18n/**.json',
      },
    },
    rules: {
      // Carried from airbnb-base/legacy
      eqeqeq: ['error', 'always', { null: 'ignore' }],
      'no-alert': 'error',
      'no-eval': 'error',
      'no-implied-eval': 'error',
      'no-new-func': 'error',
      'no-proto': 'error',
      'no-return-assign': 'error',
      'no-script-url': 'error',
      'no-sequences': 'error',
      'no-shadow': 'error',
      'no-throw-literal': 'error',
      'no-unused-expressions': 'error',
      'no-useless-call': 'error',
      'prefer-promise-reject-errors': 'error',

      camelcase: 'off',
      'no-console': 'error',
      'no-param-reassign': 'off',
      'no-unused-vars': ['error', { caughtErrors: 'none', ignoreRestSiblings: true }],
      'no-useless-assignment': 'warn',
      'preserve-caught-error': 'off',

      // Vue
      'vue/block-order': ['error', { order: ['script', 'template', 'style'] }],
      'vue/component-definition-name-casing': 'off',
      'vue/component-name-in-template-casing': [
        'error',
        'PascalCase',
        { registeredComponentsOnly: true },
      ],
      'vue/component-options-name-casing': ['error', 'PascalCase'],
      'vue/custom-event-name-casing': ['error', 'camelCase'],
      'vue/define-emits-declaration': ['error'],
      'vue/define-macros-order': [
        'error',
        { order: ['defineProps', 'defineEmits'], defineExposeLast: false },
      ],
      'vue/define-props-declaration': ['error', 'runtime'],
      'vue/html-indent': 'off',
      'vue/html-self-closing': [
        'error',
        {
          html: { void: 'always', normal: 'always', component: 'always' },
          svg: 'always',
          math: 'always',
        },
      ],
      'vue/match-component-import-name': ['error'],
      'vue/max-attributes-per-line': [
        'error',
        { singleline: { max: 20 }, multiline: { max: 1 } },
      ],
      'vue/multi-word-component-names': 'off',
      'vue/next-tick-style': ['error', 'callback'],
      'vue/no-bare-strings-in-template': [
        'error',
        {
          allowlist: [
            '(',
            ')',
            ',',
            '.',
            '&',
            '+',
            '-',
            '=',
            '*',
            '/',
            '#',
            '%',
            '!',
            '?',
            ':',
            '[',
            ']',
            '{',
            '}',
            '<',
            '>',
            '⌘',
            '📄',
            '🎉',
            '🚀',
            '💬',
            '👥',
            '📥',
            '🔖',
            '❌',
            '✅',
            '\u00b7',
            '\u2022',
            '\u2010',
            '\u2013',
            '\u2014',
            '\u2212',
            '|',
          ],
          attributes: {
            '/.+/': [
              'title',
              'aria-label',
              'aria-placeholder',
              'aria-roledescription',
              'aria-valuetext',
            ],
            input: ['placeholder'],
          },
          directives: ['v-text'],
        },
      ],
      'vue/no-empty-component-block': 'error',
      'vue/no-multiple-objects-in-class': 'error',
      'vue/no-required-prop-with-default': ['error', { autofix: false }],
      'vue/no-root-v-if': 'warn',
      'vue/no-static-inline-styles': ['error', { allowBinding: false }],
      'vue/no-template-target-blank': [
        'error',
        { allowReferrer: false, enforceDynamicLinks: 'always' },
      ],
      'vue/no-this-in-before-route-enter': 'error',
      'vue/no-undef-components': [
        'error',
        {
          ignorePatterns: [
            '^woot-',
            '^fluent-',
            '^multiselect',
            '^router-link',
            '^router-view',
            '^ninja-keys',
            '^FormulateForm',
            '^FormulateInput',
            '^highlightjs',
          ],
        },
      ],
      'vue/no-unused-emit-declarations': 'error',
      'vue/no-unused-properties': [
        'error',
        {
          groups: ['props'],
          deepData: false,
          ignorePublicMembers: false,
          unreferencedOptions: [],
        },
      ],
      'vue/no-unused-refs': 'error',
      'vue/no-use-v-else-with-v-for': 'error',
      'vue/no-useless-v-bind': [
        'error',
        { ignoreIncludesComment: false, ignoreStringEscape: false },
      ],
      'vue/no-v-html': 'off',
      'vue/no-v-text': 'error',
      'vue/padding-line-between-blocks': ['error', 'always'],
      'vue/prefer-separate-static-class': 'error',
      'vue/prefer-true-attribute-shorthand': 'error',
      'vue/require-explicit-slots': 'error',
      'vue/require-macro-variable-name': [
        'error',
        {
          defineProps: 'props',
          defineEmits: 'emit',
          defineSlots: 'slots',
          useSlots: 'slots',
          useAttrs: 'attrs',
        },
      ],
      'vue/singleline-html-element-content-newline': 'off',

      // Vue i18n
      '@intlify/vue-i18n/no-dynamic-keys': 'warn',
      '@intlify/vue-i18n/no-unused-keys': [
        'warn',
        { extensions: ['.js', '.vue'] },
      ],
    },
  },

  // Spec files
  {
    files: ['**/*.spec.{j,t}s?(x)'],
    languageOptions: {
      globals: vitestGlobals,
    },
  },

  // Story files
  {
    files: ['**/*.story.vue'],
    rules: {
      'vue/no-undef-components': [
        'error',
        { ignorePatterns: ['Variant', 'Story'] },
      ],
      'vue/no-bare-strings-in-template': 'off',
      'no-console': 'off',
    },
  },
];
