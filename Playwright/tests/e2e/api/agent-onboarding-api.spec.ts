import { expect, test } from '@utils/fixture';
import dotenv from 'dotenv';
import { fake } from '@utils/test-data';
import { AgentOnboarding, AuthComponent, AgentComponent } from '@components/api';
import { Login } from '@components/ui/login.component';
import { Cleanup } from '@utils/cleanup';
import { validateSchema } from '@utils/schema-validator';

dotenv.config();

const testConfig = {
  baseURL: process.env.BASE_URL || 'http://localhost:3000',
  admin: {
    email: process.env.TEST_USER_EMAIL || '',
    password: process.env.TEST_USER_PASSWORD || '',
  },
};

const agentPassword = process.env.TEST_USER_PASSWORD || 'Password123@#';
const generateSchemas = process.env.GENERATE_SCHEMAS === 'true';

test.describe('Agent Onboarding - API', () => {
  const testAgent = {
    ...fake.agent(),
    email: fake.email,
  };
  const agentOnboarding = new AgentOnboarding(testConfig.baseURL, 2);

  test.afterEach('Cleanup reset password token', async () => {
    await Cleanup.clearResetPasswordToken(process.env.DB_TOKEN || '');
    await Cleanup.deleteUserByEmail(testAgent.email);
  });


  test('should onboard a new agent via API', async ({ page, api }) => {
    const authComponent = new AuthComponent(testConfig.baseURL);
    const agentComponent = new AgentComponent(2);

    // Step 1: Admin authentication for agent creation
    const adminAuthHeaders = await authComponent.login(
      testConfig.admin.email,
      testConfig.admin.password
    );
    expect(adminAuthHeaders['access-token']).toBeTruthy();

    // Step 2: Create agent account via API
    const agentData = await agentComponent.create(api, adminAuthHeaders, {
      name: testAgent.name,
      email: testAgent.email,
      role: 'agent',
    });
    expect(agentData).toBeTruthy();
    await validateSchema('agent', 'create_agent', agentData, generateSchemas);

    // Step 3: Admin logout (required for password reset flow)
    const logoutResponse = await authComponent.logout(adminAuthHeaders, api);
    expect(logoutResponse.success).toBeTruthy();
    await validateSchema('auth', 'logout', logoutResponse, generateSchemas);

    // Step 4: Set password reset token in database (simulates email link)
    await agentOnboarding.updateResetPasswordToken(
      testAgent.email,
      process.env.DB_TOKEN || ''
    );

    // Step 5: Agent sets password via reset token
    const passwordResponse = await agentOnboarding.setPasswordViaAPI(
      process.env.URL_TOKEN || '',
      agentPassword
    );
    expect(passwordResponse).toBeTruthy();
    await validateSchema('auth', 'reset_password', passwordResponse, generateSchemas);

    // Step 6: Verify agent can login via API with new password
    const agentAuthHeaders = await authComponent.login(testAgent.email, agentPassword);
    expect(agentAuthHeaders['access-token']).toBeTruthy();

    // Step 7: Verify agent can login via UI with new password
    const loginComponent = new Login(page);
    await loginComponent.navigate();
    await loginComponent.login(testAgent.email, agentPassword);
    await page.waitForURL(/\/app\/accounts\/\d+\/dashboard/);
    await expect(page.getByRole('heading', { name: 'Conversations' })).toBeVisible();
  });
});
