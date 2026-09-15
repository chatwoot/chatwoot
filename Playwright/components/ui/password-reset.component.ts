import { Page } from '@playwright/test';

export class PasswordReset {
  private page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async navigate(resetPasswordToken: string, baseUrl: string = process.env.BASE_URL || 'http://localhost:3000') {
    const url = `${baseUrl}/app/auth/password/edit?reset_password_token=${resetPasswordToken}`;
    await this.page.goto(url);
  }

  getHeading() {
    return this.page.getByText('Set new password');
  }

  async fillPassword(password: string) {
    await this.page.fill('input[name="password"]', password);
  }

  async fillConfirmPassword(password: string) {
    await this.page.fill('input[placeholder="Confirm Password"]', password);
  }

  async submitForm() {
    await this.page.click('button[type="submit"]');
  }

  async setPassword(password: string) {
    await this.fillPassword(password);
    await this.fillConfirmPassword(password);
    await this.submitForm();
  }
}
