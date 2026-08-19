import { Page } from '@playwright/test';

export class ChannelSelector {
  constructor(private page: Page) {}

  getPageHeading() {
    return this.page.getByRole('heading', { name: /choose channel/i });
  }

  getApiChannelCard() {
    return this.page.getByRole('button', { name: /API.*Make a custom channel/i });
  }

  getWebsiteChannelCard() {
    return this.page.getByRole('button', { name: /Website.*Create a live-chat widget/i });
  }

  async selectApiChannel() {
    await this.getApiChannelCard().click();
  }

  async selectWebsiteChannel() {
    await this.getWebsiteChannelCard().click();
  }
}
