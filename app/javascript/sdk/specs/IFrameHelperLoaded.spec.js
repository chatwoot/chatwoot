import { IFrameHelper } from '../IFrameHelper';

describe('#IFrameHelper loaded event', () => {
  let onLoadSpy;
  let sendMessageSpy;
  let toggleCloseButtonSpy;

  beforeEach(() => {
    document.body.innerHTML = '<iframe id="chatwoot_live_chat_widget" />';
    window.$chatwoot = {
      baseDomain: '',
      darkMode: 'light',
      enableEmojiPicker: true,
      enableEndConversation: true,
      hasLoaded: false,
      hideMessageBubble: false,
      identifier: '123',
      locale: 'en',
      position: 'right',
      showPopoutButton: false,
      showUnreadMessagesDialog: true,
      user: {
        email: 'user@example.com',
        name: 'Jane Doe',
      },
      widgetStyle: 'standard',
    };
    onLoadSpy = vi.spyOn(IFrameHelper, 'onLoad').mockImplementation(() => {});
    sendMessageSpy = vi
      .spyOn(IFrameHelper, 'sendMessage')
      .mockImplementation(() => {});
    toggleCloseButtonSpy = vi
      .spyOn(IFrameHelper, 'toggleCloseButton')
      .mockImplementation(() => {});
  });

  afterEach(() => {
    onLoadSpy.mockRestore();
    sendMessageSpy.mockRestore();
    toggleCloseButtonSpy.mockRestore();
    document.body.innerHTML = '';
    delete window.$chatwoot;
  });

  it('forwards the stored identifier and user when the widget finishes loading', () => {
    IFrameHelper.events.loaded({
      config: {
        authToken: 'auth-token',
        channelConfig: {
          widgetColor: '#1f93ff',
        },
      },
    });

    expect(sendMessageSpy).toHaveBeenCalledWith('set-user', {
      identifier: '123',
      user: {
        email: 'user@example.com',
        name: 'Jane Doe',
      },
    });
  });
});
