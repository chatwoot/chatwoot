import { Page } from '@playwright/test';

export class SettingsInboxPage {
  constructor(private page: Page) {}

  async navigate() {
    await this.page.goto('/app/accounts/2/settings/inboxes/list');
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
    // Find and click the inbox row
    const inboxRow = this.getInboxByName(inboxName);
    await inboxRow.click();

    // Wait for navigation to inbox details page
    await this.page.waitForURL(/\/settings\/inboxes\/\d+/);

    // Click on Settings tab (if exists)
    const settingsTab = this.page.getByRole('link', { name: /settings/i }).first();
    if (await settingsTab.isVisible().catch(() => false)) {
      await settingsTab.click();
    }

    // Find and click delete button
    const deleteButton = this.page.getByRole('button', { name: /delete/i });
    await deleteButton.click();

    // Confirm deletion in modal/dialog
    const confirmButton = this.page.getByRole('button', { name: /yes|confirm|delete/i }).last();
    await confirmButton.click();

    // Wait for navigation back to inbox list
    await this.page.waitForURL(/\/settings\/inboxes\/list/);
  }
}
