import { Page } from '@playwright/test';

export class AddAgentsForm {
  constructor(private page: Page) {}

  getPageHeading() {
    return this.page
      .locator('form')
      .getByRole('heading', { name: 'Agents', level: 2, exact: true });
  }

  getAgentDropdown() {
    return this.page.getByPlaceholder('Pick agents for the inbox');
  }

  getAgentSelector() {
    return this.page.getByTestId('agent-selector');
  }

  getAgentOption(agentName: string) {
    return this.getAgentSelector().getByRole('button', {
      name: agentName,
      exact: true,
    });
  }

  getDropdownButtons() {
    return this.getAgentSelector().getByRole('button');
  }

  getSubmitButton() {
    return this.page.getByRole('button', { name: 'Add agents' });
  }

  async openAgentDropdown() {
    await this.getAgentDropdown().click();
  }

  async selectAgent(agentName: string) {
    await this.openAgentDropdown();
    await this.getAgentOption(agentName).waitFor({ state: 'visible' });
    await this.getAgentOption(agentName).click();
  }

  async selectAgentByIndex(index: number = 0) {
    await this.openAgentDropdown();
    const buttons = this.getDropdownButtons();
    await buttons.first().waitFor({ state: 'visible' });
    await buttons.nth(index).click();
  }

  async closeDropdown() {
    await this.page.keyboard.press('Escape');
  }

  async submitForm() {
    await this.getSubmitButton().click();
  }

  async addAgents(agentNames: string[]) {
    for (const agentName of agentNames) {
      await this.selectAgent(agentName);
    }
    await this.closeDropdown();
    await this.submitForm();
  }

  async addFirstAgent() {
    await this.selectAgentByIndex(0);
    await this.closeDropdown();
    await this.submitForm();
  }
}
