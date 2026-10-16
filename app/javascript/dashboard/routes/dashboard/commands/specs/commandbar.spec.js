import { ref } from 'vue';
import { flushPromises, mount } from '@vue/test-utils';
import { useRoute } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useCommandBar } from '@bysivin/jumpbar';
import { GENERAL_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import CommandBar from '../commandbar.vue';

const track = vi.fn();
const dispatch = vi.fn();
let getters;

vi.mock('vue-router');
vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables', () => ({
  useTrack: (...args) => track(...args),
}));
vi.mock('dashboard/composables/useKeyboardEvents', () => ({
  useKeyboardEvents: vi.fn(),
}));
vi.mock('@bysivin/jumpbar', async importOriginal => ({
  ...(await importOriginal()),
  CommandBar: { template: '<div />' },
}));

const command = (id, extra = {}) => ({
  id,
  title: id,
  section: 'Section',
  ...extra,
});

const sources = {
  goToCommands: [command('goto'), command('goto_billing')],
  appearanceCommands: [command('appearance')],
  inboxCommands: [command('inbox')],
  bulkActionCommands: [command('bulk')],
  conversationCommands: [
    command('conversation'),
    command('snooze_conversation', { page: true, placeholder: 'Type a time' }),
    command('until_custom_time', {
      parent: 'snooze_conversation',
      run: vi.fn(),
    }),
  ],
  macroCommands: [command('macro')],
  cannedResponseCommands: [command('canned')],
  accountCommands: [command('account')],
  helpCommands: [command('help')],
};

const pendingAttributes = ref(null);

vi.mock('dashboard/composables/commands/useGoToCommands', () => ({
  useGoToCommands: paywalled => ({
    goToCommands: ref(
      paywalled?.value ? [command('goto_billing')] : sources.goToCommands
    ),
  }),
}));
vi.mock('dashboard/composables/commands/useAppearanceCommands', () => ({
  useAppearanceCommands: () => ({
    appearanceCommands: ref(sources.appearanceCommands),
  }),
}));
vi.mock('dashboard/composables/commands/useInboxCommands', () => ({
  useInboxCommands: () => ({ inboxCommands: ref(sources.inboxCommands) }),
}));
vi.mock('dashboard/composables/commands/useBulkActionCommands', () => ({
  useBulkActionCommands: () => ({
    bulkActionCommands: ref(sources.bulkActionCommands),
  }),
}));
vi.mock('dashboard/composables/commands/useConversationCommands', () => ({
  useConversationCommands: () => ({
    conversationCommands: ref(sources.conversationCommands),
  }),
}));
vi.mock('dashboard/composables/commands/useMacroCommands', () => ({
  useMacroCommands: () => ({
    macroCommands: ref(sources.macroCommands),
    pendingAttributes,
    submitPendingAttributes: vi.fn(),
    dismissPendingAttributes: vi.fn(),
  }),
}));
vi.mock('dashboard/composables/commands/useCannedResponseCommands', () => ({
  useCannedResponseCommands: () => ({
    cannedResponseCommands: ref(sources.cannedResponseCommands),
  }),
}));
vi.mock('dashboard/composables/commands/useAccountCommands', () => ({
  useAccountCommands: () => ({ accountCommands: ref(sources.accountCommands) }),
}));
vi.mock('dashboard/composables/commands/useHelpCommands', () => ({
  useHelpCommands: () => ({ helpCommands: ref(sources.helpCommands) }),
}));
vi.mock('dashboard/composables/commands/useSnoozeSuggestions', () => ({
  useSnoozeSuggestions: () => ({
    snoozeCommands: () => [],
    searchSnoozeSuggestions: ({ page, text }) =>
      page === 'snooze_conversation' && text
        ? [command('parsed_date', { parent: page })]
        : [],
  }),
}));
vi.mock('dashboard/composables/commands/useBackCommands', () => ({
  useBackCommands: () => ({ backCommands: ref([]) }),
}));
vi.mock('dashboard/composables/commands/useSearchCommands', () => ({
  useSearchCommands: () => ({
    searchLoadedConversations: () => [],
    searchConversations: async () => [command('remote_conversation')],
    searchContacts: async () => [],
    searchArticles: async () => [],
    searchEverything: () => [],
  }),
}));

describe('commandbar', () => {
  let wrapper;
  const bar = useCommandBar();

  const ids = () => bar.visible.value.map(item => item.id);

  const mountCommandBar = async (props = {}) => {
    wrapper = mount(CommandBar, {
      props,
      global: { stubs: { ConversationResolveAttributesModal: true } },
    });
    await flushPromises();
    return wrapper;
  };

  beforeEach(() => {
    vi.useFakeTimers();
    getters = {
      getSelectedChat: { id: 7, meta: { sender: { name: 'Sarah' } } },
      'bulkActions/getSelectedConversationIds': [],
      'accounts/isRTL': false,
      getCurrentAccountId: 1,
    };
    useRoute.mockReturnValue({ name: 'inbox_conversation' });
    useStore.mockReturnValue({ dispatch });
    useMapGetter.mockImplementation(key => ({ value: getters[key] }));
    localStorage.clear();
  });

  afterEach(() => {
    bar.close();
    wrapper?.unmount();
    vi.useRealTimers();
  });

  it('registers every source', async () => {
    await mountCommandBar();
    bar.open();
    await flushPromises();

    expect(ids()).toEqual(
      expect.arrayContaining([
        'goto',
        'appearance',
        'inbox',
        'bulk',
        'conversation',
        'macro',
        'canned',
        'account',
        'help',
      ])
    );
  });

  it('offers only appearance and go-to commands when paywalled', async () => {
    await mountCommandBar({ isPaywalled: true });
    bar.open();
    await flushPromises();

    expect(ids()).toEqual(['goto_billing', 'appearance']);
  });

  it('names the open conversation in the scope chip', async () => {
    await mountCommandBar();

    expect(wrapper.vm.scopeLabel).toBe('Sarah');
  });

  it('counts the bulk selection in the scope chip', async () => {
    getters['bulkActions/getSelectedConversationIds'] = [1, 2, 3];
    await mountCommandBar();

    expect(wrapper.vm.scopeLabel).toBe('COMMAND_BAR.SELECTED_COUNT');
  });

  it('replaces the snooze presets with parsed dates while typing', async () => {
    await mountCommandBar();
    bar.open({ page: 'snooze_conversation' });
    await vi.advanceTimersByTimeAsync(200);
    expect(ids()).toEqual(['until_custom_time']);

    bar.setQuery('tomorrow');
    await vi.advanceTimersByTimeAsync(200);
    expect(ids()).toEqual(['parsed_date']);
  });

  it('adds remote results after the commands at the root', async () => {
    await mountCommandBar();
    bar.open({ query: 'sar' });
    await vi.advanceTimersByTimeAsync(400);

    expect(ids()).toContain('remote_conversation');
    expect(ids().indexOf('goto')).toBeLessThan(
      ids().indexOf('remote_conversation')
    );
  });

  it('tracks the selected command', async () => {
    await mountCommandBar();
    bar.open();
    await flushPromises();
    bar.select(
      command('goto', {
        title: 'Go to inbox',
        section: 'General',
        run: vi.fn(),
      })
    );

    expect(track).toHaveBeenCalledWith(GENERAL_EVENTS.COMMAND_BAR, {
      section: 'General',
      action: 'Go to inbox',
    });
  });

  it('clears the context menu conversation when closed', async () => {
    await mountCommandBar();
    bar.open();
    await flushPromises();
    bar.close();

    expect(dispatch).toHaveBeenCalledWith('setContextMenuChatId', null);
  });

  it('keeps the context menu conversation for a custom snooze', async () => {
    await mountCommandBar();
    bar.open({ page: 'snooze_conversation' });
    await flushPromises();
    bar.select(sources.conversationCommands[2]);

    expect(dispatch).not.toHaveBeenCalledWith('setContextMenuChatId', null);
  });

  it('remembers used commands per account', async () => {
    await mountCommandBar();
    bar.open();
    await flushPromises();
    bar.select(command('goto', { run: vi.fn() }));

    expect(
      JSON.parse(localStorage.getItem('command_bar_usage_1')).goto
    ).toHaveLength(1);
  });
});
