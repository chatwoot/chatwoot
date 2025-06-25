import { isOnMentionsView, isOnFoldersView } from '../actionHelpers';

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
