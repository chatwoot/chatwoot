import { Page } from '@playwright/test';

export class AddAgentModal {
  private page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  getModalTitle() {
    return this.page.locator('[data-test-id="modal-header-title"]');
  }

  getAgentNameInput() {
    return this.page.getByRole('textbox', { name: 'Agent Name' });
  }

  getEmailInput() {
    return this.page.getByRole('textbox', { name: 'Email Address' });
  }

  getRoleCombobox() {
    return this.page.getByRole('combobox', { name: 'Role' });
  }

  getSubmitButton() {
    return this.page.locator('form').getByRole('button', { name: 'Add Agent' });
  }

  getCancelButton() {
    return this.page.getByRole('button', { name: 'Cancel' });
  }

  getSuccessMessage() {
    return this.page.getByText('Agent added successfully');
  }

  async fillAgentName(name: string) {
    await this.getAgentNameInput().fill(name);
    await this.page.waitForTimeout(1000);
  }

  async fillEmail(email: string) {
    await this.getEmailInput().fill(email);
    await this.page.waitForTimeout(1000);
  }

  async submitForm() {
    await this.getSubmitButton().click();
  }

  async cancelForm() {
    await this.getCancelButton().click();
  }

  async createAgent(name: string, email: string) {
    await this.fillAgentName(name);
    await this.fillEmail(email);
    await this.submitForm();
  }
}
