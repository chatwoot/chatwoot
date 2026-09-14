import { DashboardAudioNotificationHelper } from '../DashboardAudioNotificationHelper';
import { initFaviconSwitcher } from '../faviconHelper';

vi.mock('dashboard/store', () => ({
  default: {
    getters: {
      getMineChats: vi.fn(),
      getSelectedChat: null,
      getCurrentAccountId: 1,
      getConversationById: vi.fn(),
    },
  },
}));

vi.mock('../faviconHelper', () => ({
  initFaviconSwitcher: vi.fn(),
  showBadgeOnFavicon: vi.fn(),
}));

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

describe('DashboardAudioNotificationHelper', () => {
  let store;
  let load;

  beforeEach(() => {
    load = vi.fn();
    global.Audio = vi.fn().mockImplementation(src => ({
      src,
      load,
      play: vi.fn(),
    }));

    store = {
      getters: {
        getMineChats: vi.fn().mockReturnValue([]),
        getSelectedChat: null,
        getCurrentAccountId: 1,
        getConversationById: vi.fn(),
      },
    };
  });

  it('initializes the default audio tone when the helper has no audio loaded', () => {
    const helper = new DashboardAudioNotificationHelper(store);

    helper.set({
      currentUser: { id: 1 },
      alwaysPlayAudioAlert: false,
      alertIfUnreadConversationExist: false,
      audioAlertType: 'all',
      audioAlertTone: 'ding',
    });

    expect(global.Audio).toHaveBeenCalledWith('/audio/dashboard/ding.mp3');
    expect(load).toHaveBeenCalled();
    expect(helper.audioConfig.audio).toBeTruthy();
    expect(initFaviconSwitcher).toHaveBeenCalled();
  });

  it('reinitializes audio when the alert tone changes', () => {
    const helper = new DashboardAudioNotificationHelper(store);

    helper.set({
      currentUser: { id: 1 },
      alwaysPlayAudioAlert: false,
      alertIfUnreadConversationExist: false,
      audioAlertType: 'all',
      audioAlertTone: 'ding',
    });

    helper.set({
      currentUser: { id: 1 },
      alwaysPlayAudioAlert: false,
      alertIfUnreadConversationExist: false,
      audioAlertType: 'all',
      audioAlertTone: 'bell',
    });

    expect(global.Audio).toHaveBeenNthCalledWith(
      2,
      '/audio/dashboard/bell.mp3'
    );
  });
});
