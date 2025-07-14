module.exports = {
  root: true,
  env: {
    node: true
  },
  extends: [
    'alloy',
    'alloy/typescript',
    'plugin:vue/essential',
    '@vue/typescript',

    'prettier',
    'plugin:prettier/recommended',
  ],
  rules: {
    'no-console': 'off',
    'no-debugger': process.env.NODE_ENV === 'production' ? 'error' : 'off',
    'complexity': ["error", 40],
    'max-params': ["error", 10],
    '@typescript-eslint/no-empty-interface': 'off',
    '@typescript-eslint/prefer-for-of': 'off',
    'guard-for-in': 'off',
    "@typescript-eslint/explicit-member-accessibility": "off"
  },
  parserOptions: {
    parser: '@typescript-eslint/parser'
  },
  plugins: ['@typescript-eslint', 'prettier'],
  overrides: [{
      files: [
        '**/__tests__/*.{j,t}s?(x)',
        '**/tests/unit/**/*.spec.{j,t}s?(x)'
      ],
      env: {
        jest: true
      }
    },
    // {
    //   // enable the rule specifically for TypeScript files
    //   "files": ["*.ts", "*.tsx"],
    //   "rules": {
    //     "@typescript-eslint/explicit-member-accessibility": ["error"]
    //   }
    // },
    {
      "files": ["*.ts", "*.tsx"],
      "rules": {
        "@typescript-eslint/explicit-member-accessibility": ["error"]
      }
    },
  ]
}