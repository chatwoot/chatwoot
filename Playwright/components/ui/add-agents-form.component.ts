import { Page } from '@playwright/test';

export class AddAgentsForm {
  constructor(private page: Page) {}

  getPageHeading() {
    return this.page.getByRole('heading', { name: /add agents/i });
  }

  getAgentMultiselect() {
    // Target the multiselect component
    return this.page.locator('.multiselect').first();
  }

  getAgentDropdown() {
    return this.page.locator('.multiselect__select').first();
  }

  getAgentOption(agentName: string) {
    return this.page.locator('.multiselect__element').filter({ hasText: agentName });
  }

  getSubmitButton() {
    return this.page.getByRole('button', { name: 'Add agents' });
  }

  async openAgentDropdown() {
    await this.getAgentDropdown().click();
  }

  async selectAgent(agentName: string) {
    await this.openAgentDropdown();
    await this.page.waitForTimeout(500); // Wait for dropdown to open
    await this.getAgentOption(agentName).click();
  }

  async selectAgentByIndex(index: number = 0) {
    await this.openAgentDropdown();
    await this.page.waitForTimeout(500);
    await this.page.locator('.multiselect__element').nth(index).click();
  }

  async closeDropdown() {
    await this.page.keyboard.press('Escape');
    await this.page.waitForTimeout(300);
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
