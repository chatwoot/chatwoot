import { Page } from '@playwright/test';

export class SettingsInboxPage {
  constructor(private page: Page) {}

  async navigate(accountId: number = 1) {
    await this.page.goto(`/app/accounts/${accountId}/settings/inboxes/list`);
  }

  getAddInboxButton() {
    return this.page.getByRole('link', { name: 'Add Inbox' });
  }

  async clickAddInboxButton() {
    await this.getAddInboxButton().click();
  }

  getPageHeading() {
    return this.page.getByRole('heading', { name: /inboxes/i });
  }

  getInboxTable() {
    return this.page.locator('table');
  }

  getInboxByName(name: string) {
    return this.page.getByRole('row').filter({ hasText: name });
  }

  async deleteInbox(inboxName: string) {
    const inboxRow = this.getInboxByName(inboxName);
    await inboxRow.click();

    await this.page.waitForURL(/\/settings\/inboxes\/\d+/);

    const settingsTab = this.page.getByRole('link', { name: /settings/i }).first();
    if (await settingsTab.isVisible().catch(() => false)) {
      await settingsTab.click();
    }

    const deleteButton = this.page.getByRole('button', { name: /delete/i });
    await deleteButton.click();

    const confirmButton = this.page.getByRole('button', { name: /yes|confirm|delete/i }).last();
    await confirmButton.click();

    await this.page.waitForURL(/\/settings\/inboxes\/list/);
  }
}
