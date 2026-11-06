import { Page } from '@playwright/test';

export class UserMenu {
  private page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async openMenu(userEmail: string) {
    await this.page.getByRole('button', { name: userEmail }).click();
  }

  async openMenuByName(userName: string, userEmail: string) {
    await this.page.getByRole('button', { name: `${userName} ${userEmail}` }).click();
  }

  async logout() {
    await this.page.getByRole('button', { name: 'Log out' }).click();
  }

  async openAndLogout(userEmail: string) {
    await this.openMenu(userEmail);
    await this.logout();
  }

  async openAndLogoutByName(userName: string, userEmail: string) {
    await this.openMenuByName(userName, userEmail);
    await this.logout();
  }
}
