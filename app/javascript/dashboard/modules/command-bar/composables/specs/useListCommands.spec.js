import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { emitter } from 'shared/helpers/mitt';
import {
  CMD_SWITCH_SORT,
  CMD_SWITCH_STATUS,
  CMD_SWITCH_TAB,
} from 'dashboard/helper/commandbar/events';
import { useListCommands } from '../useListCommands';

vi.mock('vue-i18n');
vi.mock('vue-router');
vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables/usePolicy');
vi.mock('shared/helpers/mitt');

describe('useListCommands', () => {
  let getters;
  let userPermissions;

  beforeEach(() => {
    userPermissions = ['administrator'];
    getters = {
      getChatListFilters: { assigneeType: 'me' },
      getChatStatusFilter: 'open',
      getChatSortFilter: 'last_activity_at_desc',
      getAppliedConversationFilters: [],
      'customViews/getActiveFolderContactId': undefined,
    };
    useI18n.mockReturnValue({ t: key => key });
    useRoute.mockReturnValue({ name: 'home' });
    useMapGetter.mockImplementation(key => ({ value: getters[key] }));
    usePolicy.mockReturnValue({
      checkPermissions: required =>
        required.some(permission => userPermissions.includes(permission)),
    });
    emitter.emit = vi.fn();
  });

  it('offers tab, status and sort pages without the current values', () => {
    const { listCommands } = useListCommands();
    const ids = listCommands.value.map(command => command.id);

    expect(ids).toEqual(
      expect.arrayContaining(['switch_tab', 'filter_status', 'sort_by'])
    );
    expect(ids).toEqual(
      expect.arrayContaining(['tab-unassigned', 'tab-all', 'status-pending'])
    );
    expect(ids).not.toContain('tab-me');
    expect(ids).not.toContain('status-open');
    expect(ids).not.toContain('sort-last_activity_at_desc');
    expect(ids).toContain('sort-priority_desc');
  });

  it('hides the tabs the user cannot open', () => {
    userPermissions = ['custom_role', 'conversation_participating_manage'];
    getters.getChatListFilters = { assigneeType: 'all' };
    const { listCommands } = useListCommands();
    const tabs = listCommands.value
      .filter(command => command.parent === 'switch_tab')
      .map(command => command.id);

    expect(tabs).toEqual(['tab-me']);
  });

  it('keeps only sorting while filters or a folder drive the list', () => {
    getters.getAppliedConversationFilters = [{ attribute_key: 'status' }];
    const { listCommands } = useListCommands();
    const ids = listCommands.value.map(command => command.id);

    expect(ids).toContain('sort_by');
    expect(ids).not.toContain('switch_tab');
    expect(ids).not.toContain('filter_status');

    getters.getAppliedConversationFilters = [];
    useRoute.mockReturnValue({ name: 'folder_conversations' });
    expect(useListCommands().listCommands.value.map(c => c.id)).not.toContain(
      'switch_tab'
    );
  });

  it('tells the list which tab, status or order to switch to', () => {
    const { listCommands } = useListCommands();
    const byId = id => listCommands.value.find(command => command.id === id);

    byId('tab-all').run();
    byId('status-resolved').run();
    byId('sort-created_at_desc').run();

    expect(emitter.emit).toHaveBeenCalledWith(CMD_SWITCH_TAB, 'all');
    expect(emitter.emit).toHaveBeenCalledWith(CMD_SWITCH_STATUS, 'resolved');
    expect(emitter.emit).toHaveBeenCalledWith(
      CMD_SWITCH_SORT,
      'created_at_desc'
    );
  });

  it('offers nothing inside a contact-scoped folder', () => {
    getters.getAppliedConversationFilters = [{ attribute_key: 'contact_id' }];
    getters['customViews/getActiveFolderContactId'] = 42;
    expect(useListCommands().listCommands.value).toEqual([]);
  });

  it('is empty away from the conversation list', () => {
    useRoute.mockReturnValue({ name: 'inbox_view' });
    expect(useListCommands().listCommands.value).toEqual([]);
  });
});
