import { Page } from '@playwright/test';

export class AgentPage {
  private page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async navigate(accountId: number = 2) {
    await this.page.goto(`/app/accounts/${accountId}/settings/agents/list`);
  }

  getPageHeading() {
    return this.page.getByRole('heading', { name: 'Agents', level: 1 });
  }

  getDescriptionText() {
    return this.page.getByText(
      'An agent is a member of your customer support team who can view and respond to user messages.'
    );
  }

  getLearnLink() {
    return this.page.getByRole('link', { name: 'Learn about user roles' });
  }

  getAddAgentButton() {
    return this.page.getByRole('button', { name: 'Add Agent' });
  }

  async openAddAgentModal() {
    await this.getAddAgentButton().click();
  }
}
