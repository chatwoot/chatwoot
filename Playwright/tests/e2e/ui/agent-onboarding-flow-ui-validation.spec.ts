import { expect, test } from '@playwright/test';
import dotenv from 'dotenv';
import { fake } from '@utils/test-data';
import { Login, AgentPage, AddAgentModal, UserMenu, PasswordReset } from '@components/ui';
import { Cleanup } from '@utils/cleanup';
import { AgentOnboarding } from '@components/api';
dotenv.config();

const testConfig = {
  baseURL: process.env.BASE_URL || 'http://localhost:3000',
  admin: {
    email: process.env.TEST_USER_EMAIL || '',
    password: process.env.TEST_USER_PASSWORD || '',
  },
};

const testUser = {
  email: process.env.TEST_USER_EMAIL || 'admin@chatwoot.com',
  password: process.env.TEST_USER_PASSWORD || 'Password123@#',
};

const agentPassword = process.env.TEST_USER_PASSWORD || 'Password123@#';

test.describe('Agent Onboarding - UI', () => {
  const newAgent = fake.agent();
  const agentOnboarding = new AgentOnboarding(testConfig.baseURL, 2);
  let loginComponent: Login;
  let agentPage: AgentPage;
  let addAgentModal: AddAgentModal;
  let userMenu: UserMenu;
  let passwordReset: PasswordReset;

  test.beforeEach(async ({ page }) => {
    loginComponent = new Login(page);
    agentPage = new AgentPage(page);
    addAgentModal = new AddAgentModal(page);
    userMenu = new UserMenu(page);
    passwordReset = new PasswordReset(page);

    await loginComponent.navigate();
    await loginComponent.login(testUser.email, testUser.password);

    await expect(page).toHaveURL(/\/app\/accounts\/\d+\/dashboard/);
    await agentPage.navigate();
  });

  test.afterEach('Cleanup reset password token', async () => {
    await Cleanup.clearResetPasswordToken(process.env.DB_TOKEN || '');
    await Cleanup.deleteUserByEmail(newAgent.email);
  });

  test('should validate all UI elements on agents page', async () => {
    await expect(agentPage.getPageHeading()).toBeVisible();
    await expect(agentPage.getDescriptionText()).toBeVisible();

    const learnLink = agentPage.getLearnLink();
    await expect(learnLink).toBeVisible();
    await expect(learnLink).toHaveAttribute('href', 'https://chwt.app/hc/agents');

    await expect(agentPage.getAddAgentButton()).toBeVisible();
    await agentPage.openAddAgentModal();

    await expect(addAgentModal.getModalTitle()).toBeVisible();
    await expect(addAgentModal.getModalTitle()).toHaveText('Add agent to your team');

    await expect(addAgentModal.getAgentNameInput()).toBeVisible();
    await expect(addAgentModal.getEmailInput()).toBeVisible();
    await expect(addAgentModal.getRoleCombobox()).toBeVisible();
    await expect(addAgentModal.getSubmitButton()).toBeVisible();
    await expect(addAgentModal.getCancelButton()).toBeVisible();

    await expect(addAgentModal.getSubmitButton()).toBeDisabled();

    await addAgentModal.getAgentNameInput().fill('Test');
    await expect(addAgentModal.getSubmitButton()).toBeDisabled();

    await addAgentModal.getAgentNameInput().clear();
    await addAgentModal.getEmailInput().fill('test@example.com');
    await expect(addAgentModal.getSubmitButton()).toBeDisabled();

    await addAgentModal.getAgentNameInput().fill('Test');
    await expect(addAgentModal.getSubmitButton()).toBeEnabled();

    await addAgentModal.cancelForm();
    await expect(addAgentModal.getModalTitle()).not.toBeVisible();
  });

  test('should create and onboard a new agent via UI', async ({ page }) => {
    // Step 1: Create agent via UI
    await agentPage.openAddAgentModal();
    await addAgentModal.createAgent(newAgent.name, newAgent.email);
    await expect(addAgentModal.getSuccessMessage()).toBeVisible();

    // Step 2: Admin logout (required for password reset flow)
    await userMenu.openAndLogout(testUser.email);
    await page.waitForURL('app/login');

    // Step 3: Set password reset token in database (simulates email link)
    await agentOnboarding.updateResetPasswordToken(
      newAgent.email,
      process.env.DB_TOKEN || ''
    );

    // Step 4: Agent sets password via reset link
    await passwordReset.navigate(process.env.URL_TOKEN || '', testConfig.baseURL);
    await expect(passwordReset.getHeading()).toBeVisible();
    await passwordReset.setPassword(agentPassword);

    // Verify agent is auto-logged in after password set
    await page.waitForURL('app/accounts/2/dashboard');
    await expect(page.getByRole('heading', { name: 'Conversations' })).toBeVisible();

    // Step 5: Verify agent can re-login with new password
    await userMenu.openAndLogoutByName(newAgent.name, newAgent.email);
    await page.waitForURL('app/login');
    await expect(page.getByRole('heading', { name: 'Login to Chatwoot' })).toBeVisible();

    await loginComponent.login(newAgent.email, agentPassword);
    await page.waitForURL('app/accounts/2/dashboard');
  });
});
