import { Page } from '@playwright/test';

export class ApiChannelForm {
  constructor(private page: Page) {}

  getChannelNameInput() {
    return this.page.getByRole('textbox', { name: 'Channel Name' });
  }

  getWebhookUrlInput() {
    return this.page.getByRole('textbox', { name: 'Webhook URL' });
  }

  getSubmitButton() {
    return this.page.getByRole('button', { name: 'Create API Channel' });
  }

  async fillChannelName(name: string) {
    await this.getChannelNameInput().fill(name);
  }

  async fillWebhookUrl(url: string) {
    await this.getWebhookUrlInput().fill(url);
  }

  async submitForm() {
    await this.getSubmitButton().click();
  }

  async createApiChannel(channelName: string, webhookUrl?: string) {
    await this.fillChannelName(channelName);
    if (webhookUrl) {
      await this.fillWebhookUrl(webhookUrl);
    }
    await this.submitForm();
  }

  getValidationError() {
    return this.page.locator('.message, .error-message').first();
  }
}
