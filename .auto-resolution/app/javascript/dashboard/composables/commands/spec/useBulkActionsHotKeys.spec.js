import { useBulkActionsHotKeys } from '../useBulkActionsHotKeys';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import wootConstants from 'dashboard/constants/globals';
import { emitter } from 'shared/helpers/mitt';

vi.mock('dashboard/composables/store');
vi.mock('vue-i18n');
vi.mock('shared/helpers/mitt');

describe('useBulkActionsHotKeys', () => {
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
    const { bulkActionsHotKeys } = useBulkActionsHotKeys();

    expect(bulkActionsHotKeys.value.length).toBeGreaterThan(0);
    expect(bulkActionsHotKeys.value).toContainEqual(
      expect.objectContaining({
        id: 'bulk_action_snooze_conversation',
        title: 'COMMAND_BAR.COMMANDS.SNOOZE_CONVERSATION',
        section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
      })
    );
    expect(bulkActionsHotKeys.value).toContainEqual(
      expect.objectContaining({
        id: 'bulk_action_reopen_conversation',
        title: 'COMMAND_BAR.COMMANDS.REOPEN_CONVERSATION',
        section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
      })
    );
    expect(bulkActionsHotKeys.value).toContainEqual(
      expect.objectContaining({
        id: 'bulk_action_resolve_conversation',
        title: 'COMMAND_BAR.COMMANDS.RESOLVE_CONVERSATION',
        section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
      })
    );
  });

  it('should include snooze options in bulk actions', () => {
    store.getters['bulkActions/getSelectedConversationIds'] = [1, 2, 3];
    const { bulkActionsHotKeys } = useBulkActionsHotKeys();

    const snoozeAction = bulkActionsHotKeys.value.find(
      action => action.id === 'bulk_action_snooze_conversation'
    );
    expect(snoozeAction).toBeDefined();
    expect(snoozeAction.children).toEqual(
      Object.values(wootConstants.SNOOZE_OPTIONS)
    );
  });

  it('should create handlers for reopen and resolve actions', () => {
    store.getters['bulkActions/getSelectedConversationIds'] = [1, 2, 3];
    const { bulkActionsHotKeys } = useBulkActionsHotKeys();

    const reopenAction = bulkActionsHotKeys.value.find(
      action => action.id === 'bulk_action_reopen_conversation'
    );
    const resolveAction = bulkActionsHotKeys.value.find(
      action => action.id === 'bulk_action_resolve_conversation'
    );

    expect(reopenAction.handler).toBeDefined();
    expect(resolveAction.handler).toBeDefined();

    reopenAction.handler();
    expect(emitter.emit).toHaveBeenCalledWith(
      'CMD_BULK_ACTION_REOPEN_CONVERSATION'
    );

    resolveAction.handler();
    expect(emitter.emit).toHaveBeenCalledWith(
      'CMD_BULK_ACTION_RESOLVE_CONVERSATION'
    );
  });

  it('should return an empty array when no conversations are selected', () => {
    store.getters['bulkActions/getSelectedConversationIds'] = [];
    const { bulkActionsHotKeys } = useBulkActionsHotKeys();

    expect(bulkActionsHotKeys.value).toEqual([]);
  });
});
