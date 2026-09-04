import { expect, test } from '@utils/fixture';
import { fake } from '@utils/test-data';
import { Cleanup } from '@utils/cleanup';
import {
  AuthComponent,
  AgentOnboarding,
  InboxComponent,
  PublicInboxComponent,
  ConversationComponent,
  ProfileComponent,
} from '@components/api';
import { Login } from '@components/ui';
import dotenv from 'dotenv';

dotenv.config();

const testConfig = {
  baseURL: process.env.BASE_URL || 'http://localhost:3000',
  accountId: 2,
  admin: {
    email: process.env.TEST_USER_EMAIL || 'admin@chatwoot.com',
    password: process.env.TEST_USER_PASSWORD || 'Password123@#',
  },
};

const agentPassword = process.env.TEST_USER_PASSWORD || 'Password123@#';

test.describe('E2E - Realtime Messaging Flow', () => {
  const testAgent = {
    ...fake.agent({ role: 'agent' }),
    email: fake.email,
  };

  const testInbox = {
    name: fake.inboxName(),
    webhookUrl: 'https://example.com/webhook',
  };

  const testContact = {
    sourceId: `contact-${Date.now()}`,
    name: fake.fullName,
    email: fake.email,
    phoneNumber: fake.phoneNumber,
  };

  let adminAuthHeaders: Record<string, string>;
  let agentAuthHeaders: Record<string, string>;
  let inboxId: number;
  let inboxIdentifier: string;
  let conversationId: number;
  let agentId: number;
  let apiAccessToken: string;

  test.beforeAll(
    'Setup: Admin login, create agent, create inbox',
    async ({ api }) => {
      const authComponent = new AuthComponent(testConfig.baseURL);
      const inboxComponent = new InboxComponent(testConfig.accountId);
      const agentOnboarding = new AgentOnboarding(
        testConfig.baseURL,
        testConfig.accountId
      );

      // Step 1: Admin authentication
      adminAuthHeaders = await authComponent.login(
        testConfig.admin.email,
        testConfig.admin.password
      );
      expect(adminAuthHeaders['access-token']).toBeTruthy();

      // Step 2: Onboard agent (creates account, sets password via reset token flow)
      const agentData = await agentOnboarding.onboardAgent(
        adminAuthHeaders,
        testAgent.name,
        testAgent.email,
        agentPassword,
        process.env.DB_TOKEN || ''
      );
      expect(agentData).toBeTruthy();
      agentId = agentData.id;

      // Step 3: Admin re-login (required after onboarding flow logout)
      adminAuthHeaders = await authComponent.login(
        testConfig.admin.email,
        testConfig.admin.password
      );
      expect(adminAuthHeaders['access-token']).toBeTruthy();

      // Step 4: Agent authentication
      agentAuthHeaders = await authComponent.login(
        testAgent.email,
        agentPassword
      );
      expect(agentAuthHeaders['access-token']).toBeTruthy();

      // Step 5: Create API inbox for testing
      const inboxResponse = await inboxComponent.createApiInbox(
        api,
        adminAuthHeaders,
        {
          name: testInbox.name,
          webhookUrl: testInbox.webhookUrl,
        }
      );
      expect(inboxResponse).toBeTruthy();
      inboxId = inboxResponse.id;
      inboxIdentifier = inboxResponse.inbox_identifier;

      // Step 6: Add agent to inbox
      await inboxComponent.addAgentToInbox(api, adminAuthHeaders, inboxId, [
        agentId,
      ]);

      // Step 7: Get agent's API access token for conversation operations
      const profileComponent = new ProfileComponent();
      const agentProfile = await profileComponent.getProfile(
        api,
        agentAuthHeaders
      );
      apiAccessToken = agentProfile.access_token || '';
      expect(apiAccessToken).toBeTruthy();
    }
  );

  test.afterAll('Cleanup: Delete test data', async ({ api }) => {
    const inboxComponent = new InboxComponent(testConfig.accountId);

    // Delete inbox (may fail if already deleted)
    try {
      await inboxComponent.deleteInbox(api, adminAuthHeaders, inboxId);
    } catch (error) {
      // Inbox may already be deleted, ignore error
    }

    // Cleanup database: reset password tokens and test user
    await Cleanup.clearResetPasswordToken(process.env.DB_TOKEN || '');
    await Cleanup.deleteUserByEmail(testAgent.email);
  });

  test('should handle realtime messaging flow E2E', async ({ page, api }) => {
    const publicInboxComponent = new PublicInboxComponent(testConfig.baseURL);
    const conversationComponent = new ConversationComponent(
      testConfig.accountId
    );
    const loginComponent = new Login(page);

    // Create contact via Public Inbox API (customer-facing endpoint)
    const contactResponse = await publicInboxComponent.createContact(
      api,
      inboxIdentifier,
      {
        sourceId: testContact.sourceId,
        name: testContact.name,
        email: testContact.email,
        phoneNumber: testContact.phoneNumber,
        customAttributes: { plan: 'trial' },
      }
    );
    expect(contactResponse).toBeTruthy();
    expect(contactResponse.source_id).toBe(testContact.sourceId);

    // Create conversation for the contact
    const conversationResponse = await publicInboxComponent.createConversation(
      api,
      inboxIdentifier,
      testContact.sourceId,
      { origin: 'e2e_test', channel: 'public_api' }
    );
    expect(conversationResponse).toBeTruthy();
    conversationId = conversationResponse.id;

    // Send first message from customer
    const customerMessage1 = 'Hello! I need help with my account.';
    const message1Response = await publicInboxComponent.createMessage(
      api,
      inboxIdentifier,
      testContact.sourceId,
      conversationId,
      {
        content: customerMessage1,
        echoId: 'customer-msg-1',
      }
    );
    expect(message1Response).toBeTruthy();
    expect(message1Response.content).toBe(customerMessage1);

    // Assign conversation to agent (so it appears in agent's inbox)
    await conversationComponent.assignConversation(
      api,
      apiAccessToken,
      conversationId,
      agentId
    );

    // Agent login via UI
    await loginComponent.navigate();
    await loginComponent.login(testAgent.email, agentPassword);
    await page.waitForURL(/\/app\/accounts\/\d+\/dashboard/);
    await expect(
      page.getByRole('heading', { name: 'Conversations' })
    ).toBeVisible();

    // Navigate to the inbox and open the conversation
    await page.goto(
      `${testConfig.baseURL}/app/accounts/${testConfig.accountId}/inbox/${inboxId}`
    );
    await page.waitForTimeout(2000); // Wait for conversations to load

    // Find and click the conversation (try data attribute first, fallback to message text)
    const conversationItem = page
      .locator(`[data-conversation-id="${conversationId}"]`)
      .first();
    if (await conversationItem.isVisible()) {
      await conversationItem.click();
    } else {
      // Fallback: look for conversation with customer message
      const conversationWithMessage = page.getByText(customerMessage1).first();
      if (await conversationWithMessage.isVisible()) {
        await conversationWithMessage.click();
      }
    }

    await page.waitForTimeout(1000);

    // Verify customer message is visible in UI
    await expect(page.getByText(customerMessage1).first()).toBeVisible();

    // Agent replies via UI
    const agentReplyMessage =
      'Hi! I can help you with that. What specific issue are you experiencing?';

    const messageInput = page.getByRole('textbox', {
      name: /Shift \+ enter for new line/i,
    });
    await messageInput.fill(agentReplyMessage);
    await page.waitForTimeout(500);

    const sendButton = page.getByRole('button', { name: /Send/i });
    await sendButton.click();
    await page.waitForTimeout(1000);

    // Verify agent reply appears in UI
    await expect(page.getByText(agentReplyMessage).first()).toBeVisible();

    // Verify messages via Account API
    const messagesResponse = await conversationComponent.getMessages(
      api,
      apiAccessToken,
      conversationId
    );
    expect(messagesResponse).toBeTruthy();
    expect(Array.isArray(messagesResponse.payload)).toBeTruthy();

    const messages = messagesResponse.payload;

    // Verify customer message exists in API response
    const customerMsg = messages.find(
      (m: any) => m.content === customerMessage1
    );
    expect(customerMsg).toBeTruthy();
    expect(customerMsg.message_type).toBe(0); // incoming

    // Verify agent reply exists in API response
    const agentMsg = messages.find((m: any) => m.content === agentReplyMessage);
    expect(agentMsg).toBeTruthy();
    expect(agentMsg.message_type).toBe(1); // outgoing

    // Test realtime sync - Customer sends message via API
    const customerMessage2 =
      'I cannot access my dashboard. It shows an error message.';
    const message2Response = await publicInboxComponent.createMessage(
      api,
      inboxIdentifier,
      testContact.sourceId,
      conversationId,
      {
        content: customerMessage2,
        echoId: 'customer-msg-2',
      }
    );
    expect(message2Response).toBeTruthy();
    expect(message2Response.content).toBe(customerMessage2);

    // Wait for websocket/realtime update to propagate
    await page.waitForTimeout(3000);

    // Verify new customer message appears in UI via realtime sync
    await expect(page.getByText(customerMessage2).first()).toBeVisible({
      timeout: 10000,
    });

    // Test realtime sync - Agent replies via API
    const agentReplyMessage2 =
      'Let me help you troubleshoot this. Can you tell me what error message you see?';
    const agentApiMessageResponse = await conversationComponent.createMessage(
      api,
      apiAccessToken,
      conversationId,
      {
        content: agentReplyMessage2,
        messageType: 'outgoing',
        private: false,
      }
    );
    expect(agentApiMessageResponse).toBeTruthy();
    expect(agentApiMessageResponse.content).toBe(agentReplyMessage2);

    // Wait for websocket/realtime update to propagate
    await page.waitForTimeout(3000);

    // Verify agent API reply appears in UI via realtime sync
    await expect(page.getByText(agentReplyMessage2).first()).toBeVisible({
      timeout: 10000,
    });
  });
});
