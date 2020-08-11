module.exports = {
  extends: ['airbnb-base/legacy', 'prettier', 'plugin:vue/recommended'],
  parserOptions: {
    parser: 'babel-eslint',
    ecmaVersion: 2020,
    sourceType: 'module',
  },
  plugins: ['html', 'prettier', 'babel'],
  rules: {
    'prettier/prettier': ['error'],
    camelcase: 'off',
    'no-param-reassign': 'off',
    'import/no-extraneous-dependencies': 'off',
    'import/prefer-default-export': 'off',
    'import/no-named-as-default': 'off',
    'jsx-a11y/no-static-element-interactions': 'off',
    'jsx-a11y/click-events-have-key-events': 'off',
    'jsx-a11y/label-has-associated-control': 'off',
    'jsx-a11y/label-has-for': 'off',
    'jsx-a11y/anchor-is-valid': 'off',
    'import/no-unresolved': 'off',
    'vue/max-attributes-per-line': ['error', {
      'singleline': 20,
      'multiline': {
        'max': 1,
        'allowFirstLine': false
      },
    }],
    'vue/html-self-closing': 'off',
    "vue/no-v-html": 'off',
    'import/extensions': ['off']

  },
  settings: {
    'import/resolver': {
      webpack: {
        config: 'config/webpack/resolve.js',
      },
    },
  },
  env: {
    browser: true,
    node: true,
    jest: true,
    jasmine: true
  },
  globals: {
    __WEBPACK_ENV__: true,
    bus: true,
  },
};
