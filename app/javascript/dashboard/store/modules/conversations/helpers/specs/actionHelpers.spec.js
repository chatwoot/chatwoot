import {
  highestMessageId,
  isOnMentionsView,
  isOnFoldersView,
  isOnParticipatingView,
} from '../actionHelpers';

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

describe('#highestMessageId', () => {
  it('answers nothing for a thread with no message', () => {
    expect(highestMessageId([])).toBeUndefined();
    expect(highestMessageId(undefined)).toBeUndefined();
  });

  // The list is sorted by time and the catch-up asks by id. An imported message is stamped
  // with when it was sent and takes its id from the INSERT, so it sits early in the list and
  // late in the sequence: taking the last one set the cursor above rows the client never
  // received, and nothing asked for them again.
  it('takes the highest id, not the newest by time', () => {
    const messages = [
      { id: 90, created_at: 1000 },
      { id: 91, created_at: 2000 },
      { id: 42, created_at: 3000 },
    ];

    expect(highestMessageId(messages)).toBe(91);
  });

  // A message still on its way out carries a uuid, and "everything after this uuid" is not
  // a question the server can answer.
  it('ignores a message that has no server id yet', () => {
    const messages = [
      { id: 7, created_at: 1000 },
      { id: 'c2a0f0e2-0b1f-4a1e-9f0e-0b1f4a1e9f0e', created_at: 2000 },
    ];

    expect(highestMessageId(messages)).toBe(7);
  });
});
