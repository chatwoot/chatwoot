import { isAConversationRoute } from '../conversationHotKeys';

describe('isAConversationRoute', () => {
  it('returns true if conversation route name is provided', () => {
    expect(isAConversationRoute('inbox_conversation')).toBe(true);
    expect(isAConversationRoute('conversation_through_inbox')).toBe(true);
    expect(isAConversationRoute('conversations_through_label')).toBe(true);
    expect(isAConversationRoute('conversations_through_team')).toBe(true);
    expect(isAConversationRoute('dashboard')).toBe(false);
  });
});
