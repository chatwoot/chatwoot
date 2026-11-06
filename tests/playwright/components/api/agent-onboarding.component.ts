import { request } from '@playwright/test';
import { RequestHandler } from '@utils/request-handler';
import { APILogger } from '@utils/logger';
import { AuthComponent } from '@components/api/auth.component';
import { AgentComponent } from '@components/api/agent.component';
import { db } from '@utils/db';
import { generateResetPasswordToken } from '@utils/devise-token';

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

  /**
   * Seeds a reset password token for the user and returns the raw token that
   * PUT /auth/password accepts. Devise also requires reset_password_sent_at to
   * be within config.reset_password_within, so it is set alongside the digest.
   */
  async seedResetPasswordToken(email: string) {
    const { raw, digest } = generateResetPasswordToken();

    const result = await db.query(
      `UPDATE users SET reset_password_token = $1, reset_password_sent_at = NOW() WHERE uid = $2`,
      [digest, email]
    );

    if (result.rowCount !== 1) {
      throw new Error(
        `Expected to seed a reset password token for exactly one user, updated ${result.rowCount} for ${email}`
      );
    }

    return raw;
  }

  /**
   * Onboards a new agent with full password setup flow.
   *
   * Flow: create agent → admin logout → set password via reset token
   *
   * Note: Admin logout is required before password reset due to Rails session management.
   */
  async onboardAgent(
    adminAuthHeaders: Record<string, string>,
    agentName: string,
    agentEmail: string,
    agentPassword: string
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
    const rawToken = await this.seedResetPasswordToken(agentEmail);
    await this.setPasswordViaAPI(rawToken, agentPassword);

    await context.dispose();

    return agentData;
  }
}
