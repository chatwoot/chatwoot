import ReplyBox from '../ReplyBox.vue';

describe('ReplyBox composer restrictions', () => {
  it('disables replies for pending AgentBot-owned conversations', () => {
    const isBotOwnedPendingConversation =
      ReplyBox.computed.isBotOwnedPendingConversation.call({
        currentChat: {
          status: 'pending',
          meta: { assignee_type: 'AgentBot' },
        },
      });

    const isEditorDisabled = ReplyBox.computed.isEditorDisabled.call({
      isOnPrivateNote: false,
      isBotOwnedPendingConversation,
      isAWhatsAppChannel: false,
      isAPIInbox: false,
      currentChat: { can_reply: true },
    });

    expect(isEditorDisabled).toBe(true);
  });

  it('keeps private notes enabled for pending AgentBot-owned conversations', () => {
    const isEditorDisabled = ReplyBox.computed.isEditorDisabled.call({
      isOnPrivateNote: true,
      isBotOwnedPendingConversation: true,
      isAWhatsAppChannel: false,
      isAPIInbox: false,
      currentChat: { can_reply: true },
    });

    expect(isEditorDisabled).toBe(false);
  });

  it('keeps replies enabled for pending human-owned conversations', () => {
    const isBotOwnedPendingConversation =
      ReplyBox.computed.isBotOwnedPendingConversation.call({
        currentChat: {
          status: 'pending',
          meta: { assignee_type: 'User' },
        },
      });

    const isEditorDisabled = ReplyBox.computed.isEditorDisabled.call({
      isOnPrivateNote: false,
      isBotOwnedPendingConversation,
      isAWhatsAppChannel: false,
      isAPIInbox: false,
      currentChat: { can_reply: true },
    });

    expect(isEditorDisabled).toBe(false);
  });
});
