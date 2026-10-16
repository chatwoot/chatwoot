import { useInboxCommands } from '../useInboxCommands';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { isAInboxViewRoute } from 'dashboard/helper/routeHelpers';

vi.mock('vue-i18n');
vi.mock('vue-router');
vi.mock('dashboard/helper/routeHelpers');
vi.mock('shared/helpers/mitt');

describe('useInboxCommands', () => {
  beforeEach(() => {
    useI18n.mockReturnValue({ t: vi.fn(key => key) });
    useRoute.mockReturnValue({ name: 'inbox_dashboard' });
    isAInboxViewRoute.mockReturnValue(true);
  });

  it('should return inbox hot keys when on an inbox view route', () => {
    const { inboxCommands } = useInboxCommands();
    expect(inboxCommands.value.length).toBeGreaterThan(0);
    expect(inboxCommands.value[0].id).toBe('snooze_notification');
  });

  it('should return an empty array when not on an inbox view route', () => {
    isAInboxViewRoute.mockReturnValue(false);
    const { inboxCommands } = useInboxCommands();
    expect(inboxCommands.value).toEqual([]);
  });

  it('should have the correct structure for snooze actions', () => {
    const { inboxCommands } = useInboxCommands();
    const snoozeNotificationAction = inboxCommands.value.find(
      action => action.id === 'snooze_notification'
    );
    expect(snoozeNotificationAction.page).toBe(true);
    expect(snoozeNotificationAction.placeholder).toBe(
      'COMMAND_BAR.SNOOZE_PLACEHOLDER'
    );
  });
});
