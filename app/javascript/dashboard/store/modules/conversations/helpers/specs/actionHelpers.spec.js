import {
  buildConversationList,
  isOnMentionsView,
  isOnFoldersView,
  isOnParticipatingView,
} from '../actionHelpers';

describe('#buildConversationList', () => {
  const requestPayload = { page: 1 };
  const conversation = { id: 1, meta: { sender: { id: 2 } } };

  const buildContext = () => ({
    commit: vi.fn(),
    dispatch: vi.fn(),
  });

  it('marks the final page as reached from pagination metadata', () => {
    const context = buildContext();

    buildConversationList(
      context,
      requestPayload,
      { payload: [conversation], meta: { next_page: null } },
      'all'
    );

    expect(context.dispatch).toHaveBeenCalledWith(
      'conversationPage/setEndReached',
      { filter: 'all' },
      { root: true }
    );
  });

  it('keeps loading when another page is available', () => {
    const context = buildContext();

    buildConversationList(
      context,
      requestPayload,
      { payload: [conversation], meta: { next_page: 2 } },
      'all'
    );

    expect(context.dispatch).not.toHaveBeenCalledWith(
      'conversationPage/setEndReached',
      expect.anything(),
      expect.anything()
    );
  });
});

describe('#isOnMentionsView', () => {
  it('return valid responses when passing the state', () => {
    expect(isOnMentionsView({ route: { name: 'conversation_mentions' } })).toBe(
      true
    );
    expect(isOnMentionsView({ route: { name: 'conversation_messages' } })).toBe(
      false
    );
  });
});

describe('#isOnFoldersView', () => {
  it('return valid responses when passing the state', () => {
    expect(isOnFoldersView({ route: { name: 'folder_conversations' } })).toBe(
      true
    );
    expect(
      isOnFoldersView({ route: { name: 'conversations_through_folders' } })
    ).toBe(true);
    expect(isOnFoldersView({ route: { name: 'conversation_messages' } })).toBe(
      false
    );
  });
});

describe('#isOnParticipatingView', () => {
  it('return valid responses when passing the state', () => {
    expect(
      isOnParticipatingView({ route: { name: 'conversation_participating' } })
    ).toBe(true);
    expect(
      isOnParticipatingView({
        route: { name: 'conversation_through_participating' },
      })
    ).toBe(true);
    expect(
      isOnParticipatingView({ route: { name: 'conversation_messages' } })
    ).toBe(false);
  });
});
