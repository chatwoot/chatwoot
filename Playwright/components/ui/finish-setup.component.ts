import { Page } from '@playwright/test';

export class FinishSetup {
  constructor(private page: Page) {}

  getPageHeading() {
    return this.page.getByRole('heading', { name: /setup complete|inbox ready/i });
  }

  getSuccessMessage() {
    return this.page.locator('text=/success|created|ready/i').first();
  }

  getGoToInboxButton() {
    return this.page.getByRole('button', { name: /go to inbox|view inbox/i });
  }

  getMoreSettingsButton() {
    return this.page.getByRole('button', { name: /more settings|settings/i });
  }

  getWebhookUrl() {
    return this.page.locator('code, pre').filter({ hasText: /http/i }).first();
  }

  async goToInbox() {
    await this.getGoToInboxButton().click();
  }

  async goToSettings() {
    await this.getMoreSettingsButton().click();
  }
}
