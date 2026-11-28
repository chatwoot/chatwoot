import { expect, test } from '@utils/fixture';
import { fake } from '@utils/test-data';
import { Cleanup } from '@utils/cleanup';
import {
  AgentOnboarding,
  AuthComponent,
  ConversationComponent,
  InboxComponent,
  ProfileComponent,
  PublicInboxComponent,
} from '@components/api';
import { Login } from '@components/ui';

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
const ADMIN_EMAIL = process.env.TEST_USER_EMAIL || 'admin@chatwoot.com';
const ADMIN_PASSWORD = process.env.TEST_USER_PASSWORD || 'Password123@#';
const AGENT_PASSWORD = process.env.TEST_USER_PASSWORD || 'Password123@#';

const MESSAGE_TYPE_INCOMING = 0;
const MESSAGE_TYPE_OUTGOING = 1;

type ConversationMessage = {
  content: string;
  message_type: number;
};

test.describe('Realtime Messaging - E2E Flow', () => {
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
  let accountId: number;
  let inboxId: number;
  let inboxIdentifier: string;
  let agentId: number;
  let agentApiAccessToken: string;

  test.beforeAll(
    'Setup: onboard an agent and give them an API inbox',
    async ({ api }) => {
      const authComponent = new AuthComponent(BASE_URL);
      const profileComponent = new ProfileComponent();

      // Admin authentication, then resolve the account under test from the profile
      adminAuthHeaders = await authComponent.login(ADMIN_EMAIL, ADMIN_PASSWORD);
      expect(adminAuthHeaders['access-token']).toBeTruthy();

      const adminProfile = await profileComponent.getProfile(
        api,
        adminAuthHeaders
      );
      accountId = adminProfile.account_id;
      expect(accountId).toBeTruthy();

      const inboxComponent = new InboxComponent(accountId);
      const agentOnboarding = new AgentOnboarding(BASE_URL, accountId);

      // Onboard the agent (creates the user, then sets its password via reset token)
      const agentData = await agentOnboarding.onboardAgent(
        adminAuthHeaders,
        testAgent.name,
        testAgent.email,
        AGENT_PASSWORD
      );
      expect(agentData).toBeTruthy();
      agentId = agentData.id;

      // Onboarding logs the admin out, so re-authenticate before continuing
      adminAuthHeaders = await authComponent.login(ADMIN_EMAIL, ADMIN_PASSWORD);
      expect(adminAuthHeaders['access-token']).toBeTruthy();

      const agentAuthHeaders = await authComponent.login(
        testAgent.email,
        AGENT_PASSWORD
      );
      expect(agentAuthHeaders['access-token']).toBeTruthy();

      const inboxResponse = await inboxComponent.createApiInbox(
        api,
        adminAuthHeaders,
        {
          name: testInbox.name,
          webhookUrl: testInbox.webhookUrl,
        }
      );
      inboxId = inboxResponse.id;
      inboxIdentifier = inboxResponse.inbox_identifier;
      expect(inboxIdentifier).toBeTruthy();

      await inboxComponent.addAgentToInbox(api, adminAuthHeaders, inboxId, [
        agentId,
      ]);

      // The agent's own token is what drives conversation calls below
      const agentProfile = await profileComponent.getProfile(
        api,
        agentAuthHeaders
      );
      agentApiAccessToken = agentProfile.access_token || '';
      expect(
        agentApiAccessToken,
        'Agent API access token is empty - enable the api_and_webhooks feature for this account'
      ).toBeTruthy();
    }
  );

  test.afterAll('Cleanup: remove the inbox and the agent', async ({ api }) => {
    const inboxComponent = new InboxComponent(accountId);

    if (inboxId) {
      await inboxComponent.deleteInbox(api, adminAuthHeaders, inboxId);
    }
    await Cleanup.deleteUserByEmail(testAgent.email);
  });

  test('should sync messages between the customer API and the agent dashboard', async ({
    page,
    api,
  }) => {
    const publicInboxComponent = new PublicInboxComponent(BASE_URL);
    const conversationComponent = new ConversationComponent(accountId);
    const loginComponent = new Login(page);

    // A customer reaches out through the public (customer-facing) inbox API
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
    expect(contactResponse.source_id).toBe(testContact.sourceId);

    const conversationResponse = await publicInboxComponent.createConversation(
      api,
      inboxIdentifier,
      testContact.sourceId,
      { origin: 'e2e_test', channel: 'public_api' }
    );
    const conversationId: number = conversationResponse.id;
    expect(conversationId).toBeTruthy();

    const customerMessage = 'Hello! I need help with my account.';
    const customerMessageResponse = await publicInboxComponent.createMessage(
      api,
      inboxIdentifier,
      testContact.sourceId,
      conversationId,
      {
        content: customerMessage,
        echoId: 'customer-msg-1',
      }
    );
    expect(customerMessageResponse.content).toBe(customerMessage);

    // Assign it so the conversation lands in this agent's dashboard
    await conversationComponent.assignConversation(
      api,
      agentApiAccessToken,
      conversationId,
      agentId
    );

    // The agent signs in and opens the conversation directly
    await loginComponent.navigate();
    await loginComponent.login(testAgent.email, AGENT_PASSWORD);
    await page.waitForURL(/\/app\/accounts\/\d+\/dashboard/);

    await page.goto(
      `/app/accounts/${accountId}/conversations/${conversationId}`
    );
    await expect(page.getByText(customerMessage).first()).toBeVisible();

    // The agent replies through the UI
    const agentUiReply =
      'Hi! I can help you with that. What specific issue are you experiencing?';
    // The reply box is a ProseMirror contenteditable, not an input, and it
    // carries no role or accessible name, so it is located by its editor class.
    const messageInput = page.locator('.ProseMirror[contenteditable="true"]');
    await messageInput.click();
    await messageInput.pressSequentially(agentUiReply);
    await page.getByRole('button', { name: /Send/i }).click();
    await expect(page.getByText(agentUiReply).first()).toBeVisible();

    // Both messages should be readable back through the account API
    await expect
      .poll(
        async () => {
          const response = await conversationComponent.getMessages(
            api,
            agentApiAccessToken,
            conversationId
          );
          return (response.payload as ConversationMessage[]).map(
            message => message.content
          );
        },
        {
          message: 'Customer message and agent reply were not both persisted',
          timeout: 30_000,
        }
      )
      .toEqual(expect.arrayContaining([customerMessage, agentUiReply]));

    const messagesResponse = await conversationComponent.getMessages(
      api,
      agentApiAccessToken,
      conversationId
    );
    const messages = messagesResponse.payload as ConversationMessage[];

    expect(
      messages.find(message => message.content === customerMessage)
        ?.message_type
    ).toBe(MESSAGE_TYPE_INCOMING);
    expect(
      messages.find(message => message.content === agentUiReply)?.message_type
    ).toBe(MESSAGE_TYPE_OUTGOING);

    // A further customer message must reach the open dashboard over the websocket
    const followUpCustomerMessage =
      'I cannot access my dashboard. It shows an error message.';
    await publicInboxComponent.createMessage(
      api,
      inboxIdentifier,
      testContact.sourceId,
      conversationId,
      {
        content: followUpCustomerMessage,
        echoId: 'customer-msg-2',
      }
    );
    await expect(
      page.getByText(followUpCustomerMessage).first()
    ).toBeVisible();

    // And so must an agent reply created out-of-band through the API
    const agentApiReply =
      'Let me help you troubleshoot this. Can you tell me what error message you see?';
    const agentApiReplyResponse = await conversationComponent.createMessage(
      api,
      agentApiAccessToken,
      conversationId,
      {
        content: agentApiReply,
        messageType: 'outgoing',
        private: false,
      }
    );
    expect(agentApiReplyResponse.content).toBe(agentApiReply);

    await expect(page.getByText(agentApiReply).first()).toBeVisible();
  });
});
