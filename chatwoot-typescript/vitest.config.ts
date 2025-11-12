import { defineConfig } from 'vitest/config';
import { resolve } from 'path';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    setupFiles: ['./test/setup.ts'],
    globalSetup: ['./test/global-setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      exclude: [
        'node_modules/',
        'test/',
        'dist/',
        '**/*.spec.ts',
        '**/*.test.ts',
        '**/*.config.ts',
        '**/index.ts',
      ],
      thresholds: {
        lines: 90,
        functions: 90,
        branches: 90,
        statements: 90,
      },
    },
    pool: 'forks',
    poolOptions: {
      forks: {
        singleFork: false,
      },
    },
    testTimeout: 10000,
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
      '@test': resolve(__dirname, './test'),
      '@config': resolve(__dirname, './src/config'),
      '@models': resolve(__dirname, './src/models'),
      '@services': resolve(__dirname, './src/services'),
      '@controllers': resolve(__dirname, './src/controllers'),
      '@jobs': resolve(__dirname, './src/jobs'),
    },
  },
});
