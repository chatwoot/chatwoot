import { useConfig } from '../useConfig';

describe('useConfig composable', () => {
  beforeEach(() => {
    global.window.chatwootWebChannel = {
      avatarUrl: 'https://test.url',
      hasAConnectedAgentBot: 'AgentBot',
      enabledFeatures: [
        'emoji_picker',
        'attachments',
        'end_conversation',
        'use_inbox_avatar_for_bot',
      ],
      preChatFormOptions: {
        pre_chat_message: '',
        pre_chat_fields: [
          {
            label: 'Email Id',
            name: 'emailAddress',
            type: 'email',
            field_type: 'standard',
            required: false,
            enabled: false,
          },
          {
            label: 'Full name',
            name: 'fullName',
            type: 'text',
            field_type: 'standard',
            required: true,
            enabled: true,
          },
        ],
      },
      preChatFormEnabled: true,
    };
  });

  it('should return correct values for computed properties', () => {
    const {
      useInboxAvatarForBot,
      hasAConnectedAgentBot,
      inboxAvatarUrl,
      channelConfig,
      hasEmojiPickerEnabled,
      hasAttachmentsEnabled,
      hasEndConversationEnabled,
      preChatFormEnabled,
      preChatFormOptions,
      shouldShowPreChatForm,
    } = useConfig();

    expect(useInboxAvatarForBot.value).toBe(true);
    expect(hasAConnectedAgentBot.value).toBe(true);
    expect(inboxAvatarUrl.value).toBe('https://test.url');

    expect(channelConfig.value).toEqual({
      avatarUrl: 'https://test.url',
      hasAConnectedAgentBot: 'AgentBot',
      enabledFeatures: [
        'emoji_picker',
        'attachments',
        'end_conversation',
        'use_inbox_avatar_for_bot',
      ],
      preChatFormOptions: {
        pre_chat_message: '',
        pre_chat_fields: [
          {
            label: 'Email Id',
            name: 'emailAddress',
            type: 'email',
            field_type: 'standard',
            required: false,
            enabled: false,
          },
          {
            label: 'Full name',
            name: 'fullName',
            type: 'text',
            field_type: 'standard',
            required: true,
            enabled: true,
          },
        ],
      },
      preChatFormEnabled: true,
    });
    expect(hasEmojiPickerEnabled.value).toBe(true);
    expect(hasAttachmentsEnabled.value).toBe(true);
    expect(hasEndConversationEnabled.value).toBe(true);
    expect(preChatFormEnabled.value).toBe(true);

    expect(preChatFormOptions.value).toEqual({
      preChatMessage: '',
      preChatFields: [
        {
          label: 'Email Id',
          name: 'emailAddress',
          type: 'email',
          field_type: 'standard',
          required: false,
          enabled: false,
        },
        {
          label: 'Full name',
          name: 'fullName',
          type: 'text',
          field_type: 'standard',
          required: true,
          enabled: true,
        },
      ],
    });

    expect(shouldShowPreChatForm.value).toBe(true);
  });
});
