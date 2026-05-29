import { defineConfig, devices } from '@playwright/test';

import dotenv from 'dotenv';
import path from 'path';
dotenv.config({ path: path.resolve(__dirname, '.env') });

const artifactDir = path.resolve(__dirname, '../../tmp/playwright');

export default defineConfig({
  testDir: './tests',
  outputDir: path.join(artifactDir, 'test-results'),
  timeout: 60 * 1000,
  expect: {
    timeout: 30 * 1000,
  },
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [['html', { outputFolder: path.join(artifactDir, 'report') }]],
  use: {
    actionTimeout: 30 * 1000,
    navigationTimeout: 30 * 1000,
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'retain-on-failure',
    headless: false,
    viewport: {
      width: 1440,
      height: 1080,
    },
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
