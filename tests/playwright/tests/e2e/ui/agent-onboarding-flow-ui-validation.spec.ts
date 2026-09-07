import { test, expect } from '@playwright/test';
import { AddAgentModal, AgentPage, Login } from '@components/ui';

const TEST_EMAIL = process.env.TEST_USER_EMAIL || 'admin@chatwoot.com';
const TEST_PASSWORD = process.env.TEST_USER_PASSWORD || 'Password123@#';

test.describe('Agent Onboarding - UI', () => {
  let loginComponent: Login;
  let agentPage: AgentPage;
  let addAgentModal: AddAgentModal;

  test.beforeEach(async ({ page }) => {
    loginComponent = new Login(page);
    agentPage = new AgentPage(page);
    addAgentModal = new AddAgentModal(page);

    await loginComponent.navigate();
    await loginComponent.login(TEST_EMAIL, TEST_PASSWORD);

    await expect(page).toHaveURL(/\/app\/accounts\/\d+\/dashboard/);
    const accountId = Number(page.url().match(/\/app\/accounts\/(\d+)\//)![1]);
    await agentPage.navigate(accountId);
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
    await expect(addAgentModal.getModalTitle()).toBeHidden();
  });
});
