import { test as base } from "@playwright/test";
import { RequestHandler } from "@utils/request-handler";
import { APILogger } from "@utils/logger";
export { expect } from '@playwright/test';
import dotenv from 'dotenv';
dotenv.config();

// Define the type for your custom fixtures
export type CustomFixtures = {
  api: RequestHandler;
  logger: APILogger;
};

// Extend the base test with your custom fixtures
export const test = base.extend<CustomFixtures>({
  logger: async ({}, use, testInfo) => {
    const logger = new APILogger();
    await use(logger);
    const logs = logger.getRecentLogs();
    if (logs && testInfo.status !== testInfo.expectedStatus) {
      console.log('\n' + logs);
    }
  },
  api: async ({request, logger}, use) => {
    const baseUrl = process.env.API_BASE_URL || 'http://localhost:3000';
    const requestHandler = new RequestHandler(request, baseUrl, logger);
    await use(requestHandler);
  },
});

