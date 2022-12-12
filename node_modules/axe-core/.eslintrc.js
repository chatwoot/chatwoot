module.exports = {
  extends: ['prettier'],
  parserOptions: {
    ecmaVersion: 9
  },
  env: {
    node: true,
    es6: true
  },
  globals: {
    axe: true
  },
  rules: {
    'no-bitwise': 2,
    camelcase: 2,
    curly: 2,
    eqeqeq: 2,
    'guard-for-in': 2,
    'wrap-iife': [2, 'any'],
    'no-use-before-define': [
      2,
      {
        functions: false
      }
    ],
    'new-cap': 2,
    'no-caller': 2,
    'no-empty': 2,
    'no-new': 2,
    'no-plusplus': 0,
    'no-undef': 2,
    'no-unused-vars': 2,
    strict: 0,
    'max-params': [2, 6],
    'max-depth': [2, 5],
    'max-len': 0,
    semi: 0,
    'no-cond-assign': 0,
    'no-debugger': 2,
    'no-eq-null': 0,
    'no-eval': 2,
    'no-unused-expressions': 0,
    'block-scoped-var': 0,
    'no-iterator': 0,
    'linebreak-style': 0,
    'no-loop-func': 0,
    'no-multi-str': 0,
    'no-proto': 0,
    'no-script-url': 0,
    'dot-notation': 2,
    'no-new-func': 0,
    'no-new-wrappers': 0,
    'no-restricted-syntax': [
      'error',
      {
        selector: 'MemberExpression[property.name=tagName]',
        message: "Don't use node.tagName, use node.nodeName instead."
      },
      {
        // node.attributes can be clobbered so is unsafe to use
        // @see https://github.com/dequelabs/axe-core/pull/1432
        selector:
          'MemberExpression[object.name=node][property.name=attributes]',
        message:
          "Don't use node.attributes, use node.hasAttributes() or axe.utils.getNodeAttributes(node) instead."
      }
    ]
  },
  overrides: [
    {
      files: ['lib/**/*.js'],
      parserOptions: {
        sourceType: 'module'
      },
      env: {
        browser: true,
        es6: true
      },
      globals: {
        window: true,
        document: true
      },
      rules: {
        'func-names': [2, 'as-needed'],
        'prefer-const': 2
      }
    },
    {
      files: ['test/**/*.js'],
      parserOptions: {
        ecmaVersion: 5
      },
      env: {
        browser: true,
        es6: false,
        mocha: true
      },
      globals: {
        assert: true,
        helpers: true,
        checks: true,
        sinon: true
      },
      plugins: ['mocha-no-only'],
      rules: {
        'new-cap': 0,
        'no-use-before-define': 0,
        'mocha-no-only/mocha-no-only': ['error']
      }
    }
  ]
};
