import { useBulkActionCommands } from '../useBulkActionCommands';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useBulkActions } from 'dashboard/composables/chatlist/useBulkActions';
import { useOrderedMacros } from 'dashboard/composables/useOrderedMacros';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import wootConstants from 'dashboard/constants/globals';
import { emitter } from 'shared/helpers/mitt';

vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables/chatlist/useBulkActions');
vi.mock('dashboard/composables/useOrderedMacros');
vi.mock('dashboard/composables/usePolicy');
vi.mock('vue-i18n');
vi.mock('vue-router');
vi.mock('shared/helpers/mitt');

const conversations = {
  1: { id: 1, inbox_id: 3, labels: ['billing'] },
  2: { id: 2, inbox_id: 4, labels: [] },
};

describe('useBulkActionCommands', () => {
  let store;
  let bulkActions;
  let disabledFeatures;

  beforeEach(() => {
    disabledFeatures = [];
    store = {
      dispatch: vi.fn(),
      getters: {
        'bulkActions/getSelectedConversationIds': [],
        getConversationById: id => conversations[id],
        'inboxAssignableAgents/getAssignableAgents': () => [
          {
            id: 9,
            name: 'Sarah',
            thumbnail: 's.png',
            availability_status: 'online',
          },
        ],
        'teams/getTeams': [{ id: 5, name: 'Sales' }],
        'labels/getLabels': [{ title: 'billing' }, { title: 'bug' }],
      },
    };
    bulkActions = {
      onAssignAgent: vi.fn(),
      onAssignTeamsForBulk: vi.fn(),
      onAssignLabels: vi.fn(),
      onRemoveLabels: vi.fn(),
      onUpdateConversations: vi.fn(),
      onExecuteMacro: vi.fn(),
    };

    useStore.mockReturnValue(store);
    useMapGetter.mockImplementation(key => ({
      value: store.getters[key],
    }));
    useBulkActions.mockReturnValue(bulkActions);
    useOrderedMacros.mockReturnValue({
      orderedMacros: { value: [{ id: 7, name: 'Close politely' }] },
    });
    usePolicy.mockReturnValue({
      isFeatureFlagEnabled: flag => !disabledFeatures.includes(flag),
    });
    useI18n.mockReturnValue({ t: vi.fn(key => key) });
    useRoute.mockReturnValue({ name: 'home' });
    emitter.emit = vi.fn();
  });

  const select = ids => {
    store.getters['bulkActions/getSelectedConversationIds'] = ids;
  };
  const byId = (commands, id) =>
    commands.value.find(action => action.id === id);

  it('should return bulk actions when conversations are selected', () => {
    select([1, 2]);
    const { bulkActionCommands } = useBulkActionCommands();

    expect(bulkActionCommands.value.map(action => action.id)).toEqual(
      expect.arrayContaining([
        'bulk_action_snooze_conversation',
        'bulk_action_reopen_conversation',
        'bulk_action_resolve_conversation',
        'bulk_action_pending_conversation',
      ])
    );
    bulkActionCommands.value.forEach(action => {
      expect(action.scopes).toEqual(['bulk']);
    });
  });

  it('should include snooze options in bulk actions', () => {
    select([1, 2]);
    const { bulkActionCommands } = useBulkActionCommands();

    expect(
      byId(bulkActionCommands, 'bulk_action_snooze_conversation').page
    ).toBe(true);
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
    select([1, 2]);
    const { bulkActionCommands } = useBulkActionCommands();

    byId(bulkActionCommands, 'bulk_action_reopen_conversation').run();
    expect(emitter.emit).toHaveBeenCalledWith(
      'CMD_BULK_ACTION_REOPEN_CONVERSATION'
    );

    byId(bulkActionCommands, 'bulk_action_resolve_conversation').run();
    expect(emitter.emit).toHaveBeenCalledWith(
      'CMD_BULK_ACTION_RESOLVE_CONVERSATION'
    );

    byId(bulkActionCommands, 'bulk_action_pending_conversation').run();
    expect(bulkActions.onUpdateConversations).toHaveBeenCalledWith(
      'pending',
      null
    );
  });

  it('assigns an agent available in every selected inbox, or nobody', () => {
    select([1, 2]);
    const { bulkActionCommands } = useBulkActionCommands();
    const agents = bulkActionCommands.value.filter(
      action => action.parent === 'bulk_assign_agent'
    );

    expect(agents.map(action => action.id)).toEqual([
      'bulk-agent-none',
      'bulk-agent-9',
    ]);
    expect(agents[1].avatar).toEqual({
      name: 'Sarah',
      src: 's.png',
      status: 'online',
    });
    agents[1].run();
    expect(bulkActions.onAssignAgent).toHaveBeenCalledWith(
      expect.objectContaining({ id: 9 })
    );
  });

  it('assigns a team or clears it', () => {
    select([1]);
    const { bulkActionCommands } = useBulkActionCommands();
    const teams = bulkActionCommands.value.filter(
      action => action.parent === 'bulk_assign_team'
    );

    expect(teams.map(action => action.id)).toEqual([
      'bulk-team-0',
      'bulk-team-5',
    ]);
    teams[1].run();
    expect(bulkActions.onAssignTeamsForBulk).toHaveBeenCalledWith({
      id: 5,
      name: 'Sales',
    });
  });

  it('adds any label and removes only labels present on the selection', () => {
    select([1, 2]);
    const { bulkActionCommands } = useBulkActionCommands();
    const add = bulkActionCommands.value.filter(
      a => a.parent === 'bulk_add_labels'
    );
    const remove = bulkActionCommands.value.filter(
      a => a.parent === 'bulk_remove_labels'
    );

    expect(add.map(action => action.title)).toEqual(['billing', 'bug']);
    expect(remove.map(action => action.title)).toEqual(['billing']);
    add[1].run();
    remove[0].run();
    expect(bulkActions.onAssignLabels).toHaveBeenCalledWith(['bug']);
    expect(bulkActions.onRemoveLabels).toHaveBeenCalledWith(['billing']);
  });

  it('runs a macro on the selection only when macros are enabled', () => {
    select([1]);
    const { bulkActionCommands } = useBulkActionCommands();
    byId(bulkActionCommands, 'bulk-macro-7').run();
    expect(bulkActions.onExecuteMacro).toHaveBeenCalledWith({
      id: 7,
      name: 'Close politely',
    });

    disabledFeatures = [FEATURE_FLAGS.MACROS];
    expect(
      useBulkActionCommands().bulkActionCommands.value.map(a => a.id)
    ).not.toContain('bulk_execute_macro');
  });

  it('offers nothing once the user has left the conversation list', () => {
    select([1, 2]);
    useRoute.mockReturnValue({ name: 'agent_list' });

    expect(useBulkActionCommands().bulkActionCommands.value).toEqual([]);
  });

  it('should return an empty array when no conversations are selected', () => {
    select([]);
    const { bulkActionCommands } = useBulkActionCommands();

    expect(bulkActionCommands.value).toEqual([]);
  });
});
