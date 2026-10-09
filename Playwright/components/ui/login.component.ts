import { Page } from '@playwright/test';

export class Login {
  private page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async navigate() {
    await this.page.goto('/');
  }

  async fillEmail(email: string) {
    await this.page.getByTestId('email_input').fill(email);
  }

  async fillPassword(password: string) {
    await this.page.getByTestId('password_input').fill(password);
  }

  async clickLoginButton() {
    await this.page.getByTestId('submit_button').click();
  }

  async login(email: string, password: string) {
    await this.fillEmail(email);
    await this.fillPassword(password);
    await this.clickLoginButton();
  }

  getEmailInput() {
    return this.page.getByTestId('email_input');
  }

  getPasswordInput() {
    return this.page.getByTestId('password_input');
  }

  getLoginButton() {
    return this.page.getByTestId('submit_button');
  }

  getLoginHeading() {
    return this.page.getByRole('heading', { name: 'Login to Chatwoot' });
  }

  getSSOLink() {
    return this.page.getByRole('link', { name: 'Login via SSO' });
  }

  getForgotPasswordLink() {
    return this.page.getByRole('link', { name: 'Forgot your password?' });
  }
}
