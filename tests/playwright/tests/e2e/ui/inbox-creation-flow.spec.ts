import { test, expect } from '@playwright/test';
import {
  AddAgentsForm,
  ApiChannelForm,
  ChannelSelector,
  FinishSetup,
  Login,
  SettingsInboxPage,
} from '@components/ui';

const TEST_EMAIL = process.env.TEST_USER_EMAIL || 'admin@chatwoot.com';
const TEST_PASSWORD = process.env.TEST_USER_PASSWORD || 'Password123@#';

test.describe('Inbox Creation - UI Flow', () => {
  const testInbox = {
    name: `Test Inbox ${Date.now()}`,
    webhookUrl: 'https://example.com/webhook',
  };

  let inboxId: number;

  test('should complete full inbox creation flow with UI validation', async ({
    page,
  }) => {
    const loginComponent = new Login(page);
    await loginComponent.navigate();
    await loginComponent.login(TEST_EMAIL, TEST_PASSWORD);
    await page.waitForURL(/\/app\/accounts\/\d+\/dashboard/);

    const accountId = Number(page.url().match(/\/app\/accounts\/(\d+)\//)![1]);
    const settingsInboxPage = new SettingsInboxPage(page);
    await settingsInboxPage.navigate(accountId);

    await expect(settingsInboxPage.getPageHeading()).toBeVisible();
    await expect(settingsInboxPage.getAddInboxButton()).toBeVisible();

    await settingsInboxPage.clickAddInboxButton();
    await page.waitForURL(/\/settings\/inboxes\/new/);

    const channelSelector = new ChannelSelector(page);
    await expect(channelSelector.getPageHeading()).toBeVisible();
    await channelSelector.selectApiChannel();

    page.on('response', async response => {
      if (
        response.url().includes('/api/v1/accounts/') &&
        response.url().includes('/inboxes') &&
        response.request().method() === 'POST' &&
        response.status() === 200
      ) {
        try {
          const responseData = await response.json();
          if (responseData.id) {
            inboxId = responseData.id;
          }
        } catch {
          // ignore non-JSON responses
        }
      }
    });

    const apiChannelForm = new ApiChannelForm(page);
    await apiChannelForm.fillChannelName(testInbox.name);
    await apiChannelForm.fillWebhookUrl(testInbox.webhookUrl);
    await apiChannelForm.submitForm();

    const addAgentsForm = new AddAgentsForm(page);
    await expect(addAgentsForm.getPageHeading()).toBeVisible();
    await addAgentsForm.addFirstAgent();

    await page.waitForURL(/\/settings\/inboxes\/.*\/finish/);
    const finishSetup = new FinishSetup(page);
    await expect(finishSetup.getSuccessMessage()).toBeVisible();

    expect(inboxId).toBeTruthy();
  });
});
