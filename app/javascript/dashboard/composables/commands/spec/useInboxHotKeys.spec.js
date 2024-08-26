import { useInboxHotKeys } from '../useInboxHotKeys';
import { useI18n } from 'dashboard/composables/useI18n';
import { useRoute } from 'dashboard/composables/route';
import { isAInboxViewRoute } from 'dashboard/helper/routeHelpers';

vi.mock('dashboard/composables/useI18n');
vi.mock('dashboard/composables/route');
vi.mock('dashboard/helper/routeHelpers');
vi.mock('shared/helpers/mitt');

describe('useInboxHotKeys', () => {
  beforeEach(() => {
    useI18n.mockReturnValue({ t: vi.fn(key => key) });
    useRoute.mockReturnValue({ name: 'inbox_dashboard' });
    isAInboxViewRoute.mockReturnValue(true);
  });

  it('should return inbox hot keys when on an inbox view route', () => {
    const { inboxHotKeys } = useInboxHotKeys();
    expect(inboxHotKeys.value.length).toBeGreaterThan(0);
    expect(inboxHotKeys.value[0].id).toBe('snooze_notification');
  });

  it('should return an empty array when not on an inbox view route', () => {
    isAInboxViewRoute.mockReturnValue(false);
    const { inboxHotKeys } = useInboxHotKeys();
    expect(inboxHotKeys.value).toEqual([]);
  });

  it('should have the correct structure for snooze actions', () => {
    const { inboxHotKeys } = useInboxHotKeys();
    const snoozeNotificationAction = inboxHotKeys.value.find(
      action => action.id === 'snooze_notification'
    );
    expect(snoozeNotificationAction).toBeDefined();
  });
});
