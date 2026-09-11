import { DashboardAudioNotificationHelper } from '../DashboardAudioNotificationHelper';
import WindowVisibilityHelper from '../WindowVisibilityHelper';
import { showBadgeOnFavicon } from '../faviconHelper';

vi.mock('../faviconHelper', () => ({
  showBadgeOnFavicon: vi.fn(),
  initFaviconSwitcher: vi.fn(),
}));

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

vi.mock('dashboard/store', () => ({ default: {} }));

vi.mock('dashboard/helper/permissionsHelper', () => ({
  getUserPermissions: vi.fn(() => ['administrator']),
}));

describe('DashboardAudioNotificationHelper', () => {
  const currentUser = { id: 7 };
  let helper;
  let store;

  const buildHelper = ({ audioAlertType, alwaysPlayAudioAlert }) => {
    const instance = new DashboardAudioNotificationHelper(store);
    instance.intializeAudio = vi.fn();
    instance.set({
      currentUser,
      alwaysPlayAudioAlert,
      alertIfUnreadConversationExist: false,
      audioAlertType,
      audioAlertTone: 'ding',
    });
    instance.playAudioAlert = vi.fn();
    instance.playAudioEvery30Seconds = vi.fn();
    return instance;
  };

  beforeEach(() => {
    vi.clearAllMocks();
    store = {
      getters: {
        getMineChats: vi.fn(() => []),
        getSelectedChat: null,
        getCurrentAccountId: 1,
        getConversationById: vi.fn(),
      },
    };
    vi.spyOn(WindowVisibilityHelper, 'isWindowVisible').mockReturnValue(false);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('onConversationAssigned', () => {
    const assignedToMe = {
      id: 42,
      status: 'open',
      meta: { assignee: { id: currentUser.id } },
    };

    it('plays the alert when a conversation is assigned to the current user', () => {
      helper = buildHelper({
        audioAlertType: 'assigned',
        alwaysPlayAudioAlert: false,
      });

      helper.onConversationAssigned(assignedToMe);

      expect(helper.playAudioAlert).toHaveBeenCalledTimes(1);
      expect(showBadgeOnFavicon).toHaveBeenCalledTimes(1);
      expect(helper.playAudioEvery30Seconds).toHaveBeenCalledTimes(1);
    });

    it('plays the alert when all alerts are enabled', () => {
      helper = buildHelper({
        audioAlertType: 'all',
        alwaysPlayAudioAlert: false,
      });

      helper.onConversationAssigned(assignedToMe);

      expect(helper.playAudioAlert).toHaveBeenCalledTimes(1);
    });

    it('does not play when the conversation is assigned to someone else', () => {
      helper = buildHelper({
        audioAlertType: 'assigned',
        alwaysPlayAudioAlert: false,
      });

      helper.onConversationAssigned({
        ...assignedToMe,
        meta: { assignee: { id: 99 } },
      });

      expect(helper.playAudioAlert).not.toHaveBeenCalled();
    });

    it('does not play when the conversation is unassigned', () => {
      helper = buildHelper({
        audioAlertType: 'assigned',
        alwaysPlayAudioAlert: false,
      });

      helper.onConversationAssigned({
        ...assignedToMe,
        meta: { assignee: null },
      });

      expect(helper.playAudioAlert).not.toHaveBeenCalled();
    });

    it('does not play when alerts are disabled', () => {
      helper = buildHelper({
        audioAlertType: 'none',
        alwaysPlayAudioAlert: false,
      });

      helper.onConversationAssigned(assignedToMe);

      expect(helper.playAudioAlert).not.toHaveBeenCalled();
    });

    it('does not play when the user only listens for unassigned conversations', () => {
      helper = buildHelper({
        audioAlertType: 'unassigned',
        alwaysPlayAudioAlert: false,
      });

      helper.onConversationAssigned(assignedToMe);

      expect(helper.playAudioAlert).not.toHaveBeenCalled();
    });

    it('does not play for pending conversations', () => {
      helper = buildHelper({
        audioAlertType: 'assigned',
        alwaysPlayAudioAlert: false,
      });

      helper.onConversationAssigned({ ...assignedToMe, status: 'pending' });

      expect(helper.playAudioAlert).not.toHaveBeenCalled();
    });

    it('does not play when the window is visible and alerts are limited to hidden windows', () => {
      WindowVisibilityHelper.isWindowVisible.mockReturnValue(true);
      helper = buildHelper({
        audioAlertType: 'assigned',
        alwaysPlayAudioAlert: false,
      });

      helper.onConversationAssigned(assignedToMe);

      expect(helper.playAudioAlert).not.toHaveBeenCalled();
    });

    it('plays when the window is visible and alerts are always enabled', () => {
      WindowVisibilityHelper.isWindowVisible.mockReturnValue(true);
      helper = buildHelper({
        audioAlertType: 'assigned',
        alwaysPlayAudioAlert: true,
      });

      helper.onConversationAssigned(assignedToMe);

      expect(helper.playAudioAlert).toHaveBeenCalledTimes(1);
    });

    it('does not play when the user is already viewing the conversation', () => {
      WindowVisibilityHelper.isWindowVisible.mockReturnValue(true);
      store.getters.getSelectedChat = { id: assignedToMe.id };
      helper = buildHelper({
        audioAlertType: 'assigned',
        alwaysPlayAudioAlert: true,
      });

      helper.onConversationAssigned(assignedToMe);

      expect(helper.playAudioAlert).not.toHaveBeenCalled();
    });

    it('does nothing before the helper is configured', () => {
      helper = new DashboardAudioNotificationHelper(store);
      helper.playAudioAlert = vi.fn();

      helper.onConversationAssigned(assignedToMe);

      expect(helper.playAudioAlert).not.toHaveBeenCalled();
    });
  });
});
