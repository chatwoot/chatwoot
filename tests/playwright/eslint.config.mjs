import js from '@eslint/js';
import playwright from 'eslint-plugin-playwright';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  {
    ignores: [
      'node_modules/',
      'dist/',
      'test-results/',
      'playwright-report/',
      'blob-report/',
      '.cache/',
      '.auth/',
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ['**/*.{js,mjs,ts}'],
    languageOptions: {
      globals: {
        __dirname: 'readonly',
        console: 'readonly',
        process: 'readonly',
      },
    },
  },
  {
    files: ['**/*.ts'],
    languageOptions: {
      parserOptions: {
        project: './tsconfig.json',
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  {
    ...playwright.configs['flat/recommended'],
    files: ['tests/**/*.ts'],
  }
);
