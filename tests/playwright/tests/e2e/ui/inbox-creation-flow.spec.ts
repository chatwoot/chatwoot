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

  let accountId: number | undefined;
  let inboxId: number | undefined;

  test.beforeEach(() => {
    accountId = undefined;
    inboxId = undefined;
  });

  test.afterEach(async ({ page }) => {
    const currentAccountId = accountId;
    const currentInboxId = inboxId;
    if (!currentAccountId || !currentInboxId) {
      return;
    }

    const settingsInboxPage = new SettingsInboxPage(page);
    await settingsInboxPage.deleteInbox(currentAccountId, currentInboxId);
    await expect
      .poll(
        () =>
          settingsInboxPage.isInboxPresent(currentAccountId, currentInboxId),
        {
          message: `Inbox ${currentInboxId} was not deleted`,
          timeout: 30_000,
        }
      )
      .toBe(false);
  });

  test('should complete full inbox creation flow with UI validation', async ({
    page,
  }) => {
    const loginComponent = new Login(page);
    await loginComponent.navigate();
    await loginComponent.login(TEST_EMAIL, TEST_PASSWORD);
    await page.waitForURL(/\/app\/accounts\/\d+\/dashboard/);

    accountId = Number(page.url().match(/\/app\/accounts\/(\d+)\//)![1]);
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
    await expect.poll(() => inboxId).toBeTruthy();

    const addAgentsForm = new AddAgentsForm(page);
    await expect(addAgentsForm.getPageHeading()).toBeVisible();
    await addAgentsForm.addFirstAgent();

    await page.waitForURL(/\/settings\/inboxes\/.*\/finish/);
    const finishSetup = new FinishSetup(page);
    await expect(finishSetup.getPageHeading()).toBeVisible();
  });
});
