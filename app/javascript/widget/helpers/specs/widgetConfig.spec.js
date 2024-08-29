import * as widgetConfig from '../widgetConfig';

describe('widgetConfig', () => {
  beforeEach(() => {
    global.chatwootWebChannel = {
      avatarUrl: 'https://test.url',
      hasAConnectedAgentBot: 'AgentBot',
      enabledFeatures: [
        'emoji_picker',
        'attachments',
        'end_conversation',
        'use_inbox_avatar_for_bot',
      ],
      preChatFormOptions: {
        pre_chat_message: 'Welcome',
        pre_chat_fields: [
          { label: 'Name', enabled: true },
          { label: 'Email', enabled: false },
        ],
      },
      preChatFormEnabled: true,
      websiteName: 'Test Website',
      workingHoursEnabled: true,
      welcomeTitle: 'Welcome to our chat',
      welcomeTagline: 'How can we help you today?',
    };
  });

  test('getChannelConfig returns the global chatwootWebChannel object', () => {
    expect(widgetConfig.getChannelConfig()).toEqual(global.chatwootWebChannel);
  });

  test('useInboxAvatarForBot returns correct value', () => {
    expect(widgetConfig.useInboxAvatarForBot()).toBe(true);
  });

  test('hasAConnectedAgentBot returns correct value', () => {
    expect(widgetConfig.hasAConnectedAgentBot()).toBe(true);
  });

  test('getInboxAvatarUrl returns correct URL', () => {
    expect(widgetConfig.getInboxAvatarUrl()).toBe('https://test.url');
  });

  test('hasEmojiPickerEnabled returns correct value', () => {
    expect(widgetConfig.hasEmojiPickerEnabled()).toBe(true);
  });

  test('hasAttachmentsEnabled returns correct value', () => {
    expect(widgetConfig.hasAttachmentsEnabled()).toBe(true);
  });

  test('hasEndConversationEnabled returns correct value', () => {
    expect(widgetConfig.hasEndConversationEnabled()).toBe(true);
  });

  test('isPreChatFormEnabled returns correct value', () => {
    expect(widgetConfig.isPreChatFormEnabled()).toBe(true);
  });

  test('getWebsiteName returns correct name', () => {
    expect(widgetConfig.getWebsiteName()).toBe('Test Website');
  });

  test('workingHoursEnabled returns correct value', () => {
    expect(widgetConfig.workingHoursEnabled()).toBe(true);
  });

  test('getWelcomeTitle returns correct title', () => {
    expect(widgetConfig.getWelcomeTitle()).toBe('Welcome to our chat');
  });

  test('getWelcomeTagline returns correct tagline', () => {
    expect(widgetConfig.getWelcomeTagline()).toBe('How can we help you today?');
  });

  test('getPreChatFormOptions returns correct options', () => {
    expect(widgetConfig.getPreChatFormOptions()).toEqual({
      preChatMessage: 'Welcome',
      preChatFields: [
        { label: 'Name', enabled: true },
        { label: 'Email', enabled: false },
      ],
    });
  });

  test('shouldShowPreChatForm returns correct value', () => {
    expect(widgetConfig.shouldShowPreChatForm()).toBe(true);
  });

  test('shouldShowPreChatForm returns false when no enabled fields', () => {
    global.chatwootWebChannel.preChatFormOptions.pre_chat_fields = [
      { label: 'Name', enabled: false },
      { label: 'Email', enabled: false },
    ];
    expect(widgetConfig.shouldShowPreChatForm()).toBe(false);
  });

  test('shouldShowPreChatForm returns false when preChatFormEnabled is false', () => {
    global.chatwootWebChannel.preChatFormEnabled = false;
    expect(widgetConfig.shouldShowPreChatForm()).toBe(false);
  });
});
