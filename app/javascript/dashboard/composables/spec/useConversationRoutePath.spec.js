import { useConversationRoutePath } from 'dashboard/composables/useConversationRoutePath';

const mockRoute = { name: '', params: {} };

vi.mock('vue-router', () => ({
  useRoute: () => mockRoute,
}));

describe('useConversationRoutePath', () => {
  beforeEach(() => {
    mockRoute.name = 'inbox_conversation';
    mockRoute.params = { accountId: '1' };
  });

  describe('buildConversationPath', () => {
    it('builds the plain conversation path', () => {
      const { buildConversationPath } = useConversationRoutePath();
      expect(buildConversationPath(5)).toBe('/app/accounts/1/conversations/5');
    });

    it('keeps the inbox context', () => {
      mockRoute.params = { accountId: '1', inbox_id: '3' };
      const { buildConversationPath } = useConversationRoutePath();
      expect(buildConversationPath(5)).toBe(
        '/app/accounts/1/inbox/3/conversations/5'
      );
    });

    it('keeps the label context', () => {
      mockRoute.params = { accountId: '1', label: 'bug' };
      const { buildConversationPath } = useConversationRoutePath();
      expect(buildConversationPath(5)).toBe(
        '/app/accounts/1/label/bug/conversations/5'
      );
    });

    it('keeps the team context', () => {
      mockRoute.params = { accountId: '1', teamId: '2' };
      const { buildConversationPath } = useConversationRoutePath();
      expect(buildConversationPath(5)).toBe(
        '/app/accounts/1/team/2/conversations/5'
      );
    });

    it('keeps the custom view context on folder routes', () => {
      mockRoute.name = 'folder_conversations';
      mockRoute.params = { accountId: '1', id: '7' };
      const { buildConversationPath } = useConversationRoutePath();
      expect(buildConversationPath(5)).toBe(
        '/app/accounts/1/custom_view/7/conversations/5'
      );
    });

    it('keeps the mentions context', () => {
      mockRoute.name = 'conversation_through_mentions';
      const { buildConversationPath } = useConversationRoutePath();
      expect(buildConversationPath(5)).toBe(
        '/app/accounts/1/mentions/conversations/5'
      );
    });

    it('keeps the participating context', () => {
      mockRoute.name = 'conversation_through_participating';
      const { buildConversationPath } = useConversationRoutePath();
      expect(buildConversationPath(5)).toBe(
        '/app/accounts/1/participating/conversations/5'
      );
    });

    it('keeps the unattended context', () => {
      mockRoute.name = 'conversation_through_unattended';
      const { buildConversationPath } = useConversationRoutePath();
      expect(buildConversationPath(5)).toBe(
        '/app/accounts/1/unattended/conversations/5'
      );
    });
  });

  describe('buildConversationListPath', () => {
    it('builds the dashboard path by default', () => {
      const { buildConversationListPath } = useConversationRoutePath();
      expect(buildConversationListPath()).toBe('/app/accounts/1/dashboard');
    });

    it('keeps the inbox context', () => {
      mockRoute.params = { accountId: '1', inbox_id: '3' };
      const { buildConversationListPath } = useConversationRoutePath();
      expect(buildConversationListPath()).toBe('/app/accounts/1/inbox/3');
    });

    it('keeps the label context', () => {
      mockRoute.params = { accountId: '1', label: 'bug' };
      const { buildConversationListPath } = useConversationRoutePath();
      expect(buildConversationListPath()).toBe('/app/accounts/1/label/bug');
    });

    it('keeps the team context', () => {
      mockRoute.params = { accountId: '1', teamId: '2' };
      const { buildConversationListPath } = useConversationRoutePath();
      expect(buildConversationListPath()).toBe('/app/accounts/1/team/2');
    });

    it('keeps the custom view context on folder routes', () => {
      mockRoute.name = 'folder_conversations';
      mockRoute.params = { accountId: '1', id: '7' };
      const { buildConversationListPath } = useConversationRoutePath();
      expect(buildConversationListPath()).toBe('/app/accounts/1/custom_view/7');
    });

    it('keeps the mentions context', () => {
      mockRoute.name = 'conversation_mentions';
      const { buildConversationListPath } = useConversationRoutePath();
      expect(buildConversationListPath()).toBe(
        '/app/accounts/1/mentions/conversations'
      );
    });

    it('keeps the participating context', () => {
      mockRoute.name = 'conversation_participating';
      const { buildConversationListPath } = useConversationRoutePath();
      expect(buildConversationListPath()).toBe(
        '/app/accounts/1/participating/conversations'
      );
    });

    it('keeps the unattended context', () => {
      mockRoute.name = 'conversation_unattended';
      const { buildConversationListPath } = useConversationRoutePath();
      expect(buildConversationListPath()).toBe(
        '/app/accounts/1/unattended/conversations'
      );
    });
  });
});
