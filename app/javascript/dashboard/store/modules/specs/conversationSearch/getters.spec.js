import { getters } from '../../conversationSearch';

describe('#getters', () => {
  it('getConversations', () => {
    const state = {
      records: [{ id: 1, messages: [{ id: 1, content: 'value' }] }],
    };
    expect(getters.getConversations(state)).toEqual([
      { id: 1, messages: [{ id: 1, content: 'value' }] },
    ]);
  });

  it('getContactRecords', () => {
    const state = {
      contactRecords: [{ id: 1, name: 'Contact 1' }],
    };
    expect(getters.getContactRecords(state)).toEqual([
      { id: 1, name: 'Contact 1' },
    ]);
  });

  it('getConversationRecords', () => {
    const state = {
      conversationRecords: [{ id: 1, title: 'Conversation 1' }],
    };
    expect(getters.getConversationRecords(state)).toEqual([
      { id: 1, title: 'Conversation 1' },
    ]);
  });

  it('getMessageRecords', () => {
    const state = {
      messageRecords: [{ id: 1, content: 'Message 1' }],
    };
    expect(getters.getMessageRecords(state)).toEqual([
      { id: 1, content: 'Message 1' },
    ]);
  });

  it('getArticleRecords', () => {
    const state = {
      articleRecords: [{ id: 1, title: 'Article 1' }],
    };
    expect(getters.getArticleRecords(state)).toEqual([
      { id: 1, title: 'Article 1' },
    ]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: false,
        isSearchCompleted: true,
        contact: { isFetching: true },
        message: { isFetching: false },
        conversation: { isFetching: false },
        article: { isFetching: false },
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: false,
      isSearchCompleted: true,
      contact: { isFetching: true },
      message: { isFetching: false },
      conversation: { isFetching: false },
      article: { isFetching: false },
    });
  });
});
