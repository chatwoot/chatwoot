module.exports = {
  env: {
    browser: true,
    es2020: true
  },
  extends: [
    'eslint:recommended',
    'plugin:react/recommended',
    'plugin:prettier/recommended',
    'plugin:jest/recommended'
  ],
  parser: 'babel-eslint',
  parserOptions: {
    ecmaFeatures: {
      jsx: true
    },
    ecmaVersion: 11,
    sourceType: 'module'
  },
  plugins: ['react', 'jest'],
  rules: {
    'react/prop-types': 0
  },
  overrides: [
    {
      files: ['scripts/*', '.eslintrc.js', 'babel.config.js'],
      env: {
        node: true
      }
    }
  ]
};
