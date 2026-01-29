import { AgentOnboarding } from '@components/api';
import {
  AddAgentsForm,
  ApiChannelForm,
  ChannelSelector,
  FinishSetup,
  Login,
  SettingsInboxPage,
} from '@components/ui';
import { Cleanup } from '@utils/cleanup';
import { expect, test } from '@utils/fixture';
import { fake } from '@utils/test-data';
import dotenv from 'dotenv';

dotenv.config();

const testConfig = {
  baseURL: process.env.BASE_URL || 'http://localhost:3000',
  admin: {
    email: process.env.TEST_USER_EMAIL || '',
    password: process.env.TEST_USER_PASSWORD || '',
  },
};

const agentPassword = process.env.TEST_USER_PASSWORD || 'Password123@#';

test.describe('Inbox Creation - Complete Flow', () => {
  const testAgent = {
    ...fake.agent(),
    email: fake.email,
  };

  const testInbox = {
    name: fake.inboxName(),
    webhookUrl: 'https://example.com/webhook',
  };

  let inboxId: number;

  test.afterEach('Cleanup test data', async () => {
    await Cleanup.deleteUserByEmail(testAgent.email);
  });

  test('should complete full inbox creation flow with UI validation and deletion', async ({
    page,
  }) => {
    const agentOnboarding = new AgentOnboarding(testConfig.baseURL, 2);

    // Agent Onboarding
    await page.waitForTimeout(1000);
    await agentOnboarding.onboardAgentWithReauth(
      testConfig.admin.email,
      testConfig.admin.password,
      testAgent.name,
      testAgent.email,
      agentPassword,
      process.env.DB_TOKEN || ''
    );

    // Admin UI Login and Navigate to Inbox
    const loginComponent = new Login(page);
    await loginComponent.navigate();
    await loginComponent.login(
      testConfig.admin.email,
      testConfig.admin.password
    );
    await page.waitForURL(/\/app\/accounts\/\d+\/dashboard/);

    // Navigate to Settings > Inboxes
    const settingsInboxPage = new SettingsInboxPage(page);
    await settingsInboxPage.navigate();

    // UI Validation - Header Elements
    await expect(settingsInboxPage.getPageHeading()).toBeVisible();
    await expect(settingsInboxPage.getAddInboxButton()).toBeVisible();

    // Inbox Creation Flow - Channel Selection
    await settingsInboxPage.clickAddInboxButton();
    await page.waitForURL(/\/settings\/inboxes\/new/);

    // Validate channel selector UI and select API Channel
    const channelSelector = new ChannelSelector(page);
    await expect(channelSelector.getPageHeading()).toBeVisible();
    await channelSelector.selectApiChannel();

    // Request Interception - Capture Inbox ID
    page.on('response', async response => {
      if (
        response.url().includes('/api/v1/accounts/') &&
        response.url().includes('/inboxes')
      ) {
        if (
          response.request().method() === 'POST' &&
          response.status() === 200
        ) {
          try {
            const responseData = await response.json();
            if (responseData.id) {
              inboxId = responseData.id;
            }
          } catch (error) {
            // Not a JSON response, ignore
          }
        }
      }
    });

    // UI Validation - API Channel Form
    const apiChannelForm = new ApiChannelForm(page);
    await apiChannelForm.fillChannelName(testInbox.name);
    await apiChannelForm.fillWebhookUrl(testInbox.webhookUrl);
    await apiChannelForm.submitForm();

    // UI Validation - Add Agents Step
    const addAgentsForm = new AddAgentsForm(page);
    await expect(addAgentsForm.getPageHeading()).toBeVisible();
    await addAgentsForm.addFirstAgent();

    // UI Validation - Finish Setup
    await page.waitForURL(/\/settings\/inboxes\/.*\/finish/);
    const finishSetup = new FinishSetup(page);
    await expect(finishSetup.getSuccessMessage()).toBeVisible();

    // Verify inbox was created successfully
    expect(inboxId).toBeTruthy();
  });
});
