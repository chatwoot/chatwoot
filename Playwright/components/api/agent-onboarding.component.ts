import { request } from '@playwright/test';
import { RequestHandler } from '@utils/request-handler';
import { APILogger } from '@utils/logger';
import { AuthComponent } from '@components/api/auth.component';
import { AgentComponent } from '@components/api/agent.component';
import { db } from '@utils/db';

export class AgentOnboarding {
  private baseUrl: string;
  private accountId: number;

  constructor(baseUrl: string = process.env.BASE_URL || 'http://localhost:3000', accountId: number = 2) {
    this.baseUrl = baseUrl;
    this.accountId = accountId;
  }

  async setPasswordViaAPI(resetPasswordToken: string, password: string) {
    const context = await request.newContext();
    const logger = new APILogger();
    const api = new RequestHandler(context, this.baseUrl, logger);

    const response = await api
      .logs(true)
      .url(this.baseUrl)
      .path('/auth/password')
      .headers({
        'Content-Type': 'application/json',
      })
      .body({
        reset_password_token: resetPasswordToken,
        password: password,
        password_confirmation: password,
      })
      .putRequest(200);

    await context.dispose();
    return response;
  }

  async updateResetPasswordToken(email: string, token: string) {
    await db.query(
      `UPDATE users SET reset_password_token = $1 WHERE uid = $2`,
      [token, email]
    );
  }

  /**
   * Onboards a new agent with full password setup flow.
   *
   * Flow: create agent → admin logout → set password via reset token
   *
   * Note: Admin logout is required before password reset due to Rails session management.
   */
  async onboardAgent(
    adminAuthHeaders: any,
    agentName: string,
    agentEmail: string,
    agentPassword: string,
    resetPasswordToken: string
  ) {
    console.log(`[AgentOnboarding] Starting onboarding for ${agentEmail}`);

    const authComponent = new AuthComponent(this.baseUrl);
    const agentComponent = new AgentComponent(this.accountId);

    const context = await request.newContext();
    const logger = new APILogger();
    const api = new RequestHandler(context, this.baseUrl, logger);

    // Create agent account
    const agentData = await agentComponent.create(api, adminAuthHeaders, {
      name: agentName,
      email: agentEmail,
      role: 'agent',
    });

    // Admin must logout before password reset (Rails session requirement)
    await authComponent.logout(adminAuthHeaders, api);

    // Set password via reset token mechanism
    await this.updateResetPasswordToken(agentEmail, resetPasswordToken);
    await this.setPasswordViaAPI(process.env.URL_TOKEN || resetPasswordToken, agentPassword);

    await context.dispose();

    return agentData;
  }

  /**
   * Onboards a new agent with full authentication cycle including admin re-login.
   *
   * Flow: admin login → create agent → admin logout → set password → admin re-login
   *
   * This method handles the complete auth cycle, useful for UI tests where admin
   * session state needs to be maintained after agent onboarding.
   */
  async onboardAgentWithReauth(
    adminEmail: string,
    adminPassword: string,
    agentName: string,
    agentEmail: string,
    agentPassword: string,
    resetPasswordToken: string
  ) {
    console.log(`[AgentOnboarding] Starting full onboarding with reauth for ${agentEmail}`);

    const authComponent = new AuthComponent(this.baseUrl);
    const agentComponent = new AgentComponent(this.accountId);

    const context = await request.newContext();
    const logger = new APILogger();
    const api = new RequestHandler(context, this.baseUrl, logger);

    // Admin authentication
    const adminAuthHeaders = await authComponent.login(adminEmail, adminPassword);

    // Create agent account
    const agentData = await agentComponent.create(api, adminAuthHeaders, {
      name: agentName,
      email: agentEmail,
      role: 'agent',
    });

    // Admin must logout before password reset (Rails session requirement)
    await authComponent.logout(adminAuthHeaders, api);

    // Set password via reset token mechanism
    await this.updateResetPasswordToken(agentEmail, resetPasswordToken);
    await this.setPasswordViaAPI(process.env.URL_TOKEN || resetPasswordToken, agentPassword);

    // Admin re-login to restore session state
    const newAdminAuthHeaders = await authComponent.login(adminEmail, adminPassword);

    await context.dispose();

    return { agentData, adminAuthHeaders: newAdminAuthHeaders };
  }
}
