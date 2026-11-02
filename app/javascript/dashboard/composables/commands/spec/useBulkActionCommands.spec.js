import { useBulkActionCommands } from '../useBulkActionCommands';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import wootConstants from 'dashboard/constants/globals';
import { emitter } from 'shared/helpers/mitt';

vi.mock('dashboard/composables/store');
vi.mock('vue-i18n');
vi.mock('shared/helpers/mitt');

describe('useBulkActionCommands', () => {
  let store;

  beforeEach(() => {
    store = {
      getters: {
        'bulkActions/getSelectedConversationIds': [],
      },
    };

    useStore.mockReturnValue(store);
    useMapGetter.mockImplementation(key => ({
      value: store.getters[key],
    }));

    useI18n.mockReturnValue({ t: vi.fn(key => key) });
    emitter.emit = vi.fn();
  });

  it('should return bulk actions when conversations are selected', () => {
    store.getters['bulkActions/getSelectedConversationIds'] = [1, 2, 3];
    const { bulkActionCommands } = useBulkActionCommands();

    expect(bulkActionCommands.value.length).toBeGreaterThan(0);
    expect(bulkActionCommands.value).toContainEqual(
      expect.objectContaining({
        id: 'bulk_action_snooze_conversation',
        title: 'COMMAND_BAR.COMMANDS.SNOOZE_CONVERSATION',
        section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
      })
    );
    expect(bulkActionCommands.value).toContainEqual(
      expect.objectContaining({
        id: 'bulk_action_reopen_conversation',
        title: 'COMMAND_BAR.COMMANDS.REOPEN_CONVERSATION',
        section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
      })
    );
    expect(bulkActionCommands.value).toContainEqual(
      expect.objectContaining({
        id: 'bulk_action_resolve_conversation',
        title: 'COMMAND_BAR.COMMANDS.RESOLVE_CONVERSATION',
        section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
      })
    );
  });

  it('should include snooze options in bulk actions', () => {
    store.getters['bulkActions/getSelectedConversationIds'] = [1, 2, 3];
    const { bulkActionCommands } = useBulkActionCommands();

    const snoozeAction = bulkActionCommands.value.find(
      action => action.id === 'bulk_action_snooze_conversation'
    );
    expect(snoozeAction.page).toBe(true);
    const options = bulkActionCommands.value
      .filter(action => action.parent === 'bulk_action_snooze_conversation')
      .map(action => action.id);
    expect(options).toEqual(
      Object.values(wootConstants.SNOOZE_OPTIONS).map(
        option => `bulk_action_snooze_conversation-${option}`
      )
    );
  });

  it('should emit the bus event when reopen and resolve run', () => {
    store.getters['bulkActions/getSelectedConversationIds'] = [1, 2, 3];
    const { bulkActionCommands } = useBulkActionCommands();

    const reopenAction = bulkActionCommands.value.find(
      action => action.id === 'bulk_action_reopen_conversation'
    );
    const resolveAction = bulkActionCommands.value.find(
      action => action.id === 'bulk_action_resolve_conversation'
    );

    reopenAction.run();
    expect(emitter.emit).toHaveBeenCalledWith(
      'CMD_BULK_ACTION_REOPEN_CONVERSATION'
    );

    resolveAction.run();
    expect(emitter.emit).toHaveBeenCalledWith(
      'CMD_BULK_ACTION_RESOLVE_CONVERSATION'
    );
  });

  it('should return an empty array when no conversations are selected', () => {
    store.getters['bulkActions/getSelectedConversationIds'] = [];
    const { bulkActionCommands } = useBulkActionCommands();

    expect(bulkActionCommands.value).toEqual([]);
  });
});
