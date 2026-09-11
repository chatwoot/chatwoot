import { test, expect } from '@playwright/test';
import { Login } from '@components/ui';

const TEST_EMAIL = process.env.TEST_USER_EMAIL || 'admin@chatwoot.com';
const TEST_PASSWORD = process.env.TEST_USER_PASSWORD || 'Password123@#';
const INVALID_PASSWORD = 'Password';

test.describe('Login page', () => {
  let loginComponent: Login;

  test.beforeEach(async ({ page }) => {
    loginComponent = new Login(page);
    await loginComponent.navigate();
  });

  test('should allow user to login with valid credentials', async ({
    page,
  }) => {
    await loginComponent.login(TEST_EMAIL, TEST_PASSWORD);
    await expect(page).toHaveURL(/\/app\/accounts\/\d+\/dashboard/);
  });

  test('renders all critical components', async ({ page }) => {
    await expect(page).toHaveTitle('Chatwoot');
    await expect(loginComponent.getLoginHeading()).toBeVisible();

    const ssoLink = loginComponent.getSSOLink();
    await expect(ssoLink).toBeVisible();
    await expect(ssoLink).toHaveAttribute('href', '/app/login/sso');

    const orDivider = page.getByText('Or', { exact: true });
    await expect(orDivider).toBeVisible();
    await expect(orDivider).toHaveText('Or');

    const emailInput = loginComponent.getEmailInput();
    await expect(emailInput).toBeVisible();
    await expect(emailInput).toHaveAttribute('name', 'email_address');
    await expect(page.getByText('Email')).toBeVisible();

    const passwordInput = loginComponent.getPasswordInput();
    await expect(passwordInput).toBeVisible();
    await expect(passwordInput).toHaveAttribute('type', 'password');
    await expect(page.getByText('PasswordForgot your password?')).toBeVisible();

    const togglePasswordButton = page.getByRole('button', {
      name: 'Show password',
    });
    await expect(togglePasswordButton).toBeVisible();
    await expect(togglePasswordButton).toHaveAttribute('type', 'button');
    await expect(togglePasswordButton.locator('.i-lucide-eye')).toBeVisible();

    const forgotPasswordLink = loginComponent.getForgotPasswordLink();
    await expect(forgotPasswordLink).toBeVisible();
    await expect(forgotPasswordLink).toHaveAttribute(
      'href',
      '/app/auth/reset/password'
    );

    const loginButton = loginComponent.getLoginButton();
    await expect(loginButton).toBeVisible();
    await expect(loginButton).toHaveAttribute('type', 'submit');
  });

  test('should show error for invalid password', async ({ page }) => {
    await loginComponent.login(TEST_EMAIL, INVALID_PASSWORD);

    await expect(
      page.getByText('Invalid login credentials. Please try again.')
    ).toBeVisible();

    await expect(page).toHaveURL(/\/app\/login/);
  });
});
