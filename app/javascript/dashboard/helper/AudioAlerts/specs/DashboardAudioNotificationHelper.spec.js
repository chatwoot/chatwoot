import { DashboardAudioNotificationHelper } from '../DashboardAudioNotificationHelper';
import WindowVisibilityHelper from '../WindowVisibilityHelper';
import { showBadgeOnFavicon } from '../faviconHelper';

vi.mock('dashboard/store', () => ({ default: {} }));
vi.mock('../faviconHelper', () => ({
  showBadgeOnFavicon: vi.fn(),
  initFaviconSwitcher: vi.fn(),
}));

describe('dashboard bot handoff alerts', () => {
  let helper;
  let conversation;

  beforeEach(() => {
    vi.useFakeTimers();
    helper = new DashboardAudioNotificationHelper({});
    helper.currentUser = { id: 7 };
    helper.notificationConfig = {
      audioAlertType: ['all'],
      playAlertOnlyWhenHidden: true,
      alertIfUnreadConversationExist: true,
    };
    conversation = {
      id: 12,
      meta: { assignee_type: 'User', assignee: { id: 7 } },
    };
    vi.spyOn(helper, 'playAudioAlert').mockResolvedValue();
    vi.spyOn(helper.store, 'hasConversationPermission').mockReturnValue(true);
    vi.spyOn(helper.store, 'isCurrentConversation').mockReturnValue(false);
    vi.spyOn(WindowVisibilityHelper, 'isWindowVisible').mockReturnValue(false);
  });

  afterEach(() => {
    vi.clearAllTimers();
    vi.useRealTimers();
    vi.restoreAllMocks();
    vi.clearAllMocks();
  });

  it('plays sound, badges the tab, and starts recurring alerts without a new message', () => {
    helper.onConversationBotHandoff(conversation);

    expect(helper.playAudioAlert).toHaveBeenCalledOnce();
    expect(showBadgeOnFavicon).toHaveBeenCalledOnce();
    expect(vi.getTimerCount()).toBe(1);
  });

  it.each([
    ['none', 7, false],
    ['mine', 7, true],
    ['mine', 8, false],
    ['unassigned', null, true],
    ['unassigned', 7, false],
    ['notme', 8, true],
    ['notme', 7, false],
  ])(
    'respects %s alerts for assignee %s',
    (filter, assigneeId, shouldAlert) => {
      helper.notificationConfig.audioAlertType = [filter];
      conversation.meta.assignee = assigneeId ? { id: assigneeId } : null;

      helper.onConversationBotHandoff(conversation);

      expect(helper.playAudioAlert).toHaveBeenCalledTimes(shouldAlert ? 1 : 0);
      expect(showBadgeOnFavicon).toHaveBeenCalledTimes(shouldAlert ? 1 : 0);
      expect(vi.getTimerCount()).toBe(shouldAlert ? 1 : 0);
    }
  );

  it('suppresses alerts without conversation permissions', () => {
    helper.store.hasConversationPermission.mockReturnValue(false);
    helper.onConversationBotHandoff(conversation);

    expect(helper.playAudioAlert).not.toHaveBeenCalled();
    expect(showBadgeOnFavicon).not.toHaveBeenCalled();
    expect(vi.getTimerCount()).toBe(0);
  });

  it.each([
    [true, false, false],
    [false, true, false],
    [false, false, true],
  ])(
    'respects active-window preferences (%s, %s)',
    (hiddenOnly, isSelected, shouldAlert) => {
      WindowVisibilityHelper.isWindowVisible.mockReturnValue(true);
      helper.notificationConfig.playAlertOnlyWhenHidden = hiddenOnly;
      helper.store.isCurrentConversation.mockReturnValue(isSelected);

      helper.onConversationBotHandoff(conversation);

      expect(helper.playAudioAlert).toHaveBeenCalledTimes(shouldAlert ? 1 : 0);
      expect(showBadgeOnFavicon).toHaveBeenCalledTimes(shouldAlert ? 1 : 0);
      expect(vi.getTimerCount()).toBe(shouldAlert ? 1 : 0);
    }
  );
});
