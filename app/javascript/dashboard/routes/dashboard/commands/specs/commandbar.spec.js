import { ref } from 'vue';
import { flushPromises, mount } from '@vue/test-utils';
import { emitter } from 'shared/helpers/mitt';
import { CMD_SNOOZE_CONVERSATION } from 'dashboard/helper/commandbar/events';
import { GENERAL_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import CommandBar from '../commandbar.vue';

vi.mock('@chatwoot/ninja-keys', () => ({}));

const dispatch = vi.fn();
const track = vi.fn();

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch }),
}));

vi.mock('dashboard/composables', () => ({
  useTrack: (...args) => track(...args),
}));

const hotKeySources = {
  goToAppearanceHotKeys: [{ id: 'appearance' }],
  inboxHotKeys: [{ id: 'inbox' }],
  goToCommandHotKeys: [{ id: 'goto' }],
  bulkActionsHotKeys: [
    { id: 'bulk' },
    { id: 'until_tomorrow', parent: 'bulk_action_snooze_conversation' },
  ],
  conversationHotKeys: [
    { id: 'conversation' },
    { id: 'until_tomorrow', parent: 'snooze_conversation' },
    { id: 'until_tomorrow', parent: 'snooze_notification' },
    { id: 'until_tomorrow', parent: 'other_menu' },
  ],
  macroHotKeys: [{ id: 'execute_a_macro' }],
};

const pendingAttributes = ref(null);

vi.mock('dashboard/composables/commands/useAppearanceHotKeys', () => ({
  useAppearanceHotKeys: () => ({
    goToAppearanceHotKeys: ref(hotKeySources.goToAppearanceHotKeys),
  }),
}));

vi.mock('dashboard/composables/commands/useInboxHotKeys', () => ({
  useInboxHotKeys: () => ({ inboxHotKeys: ref(hotKeySources.inboxHotKeys) }),
}));

vi.mock('dashboard/composables/commands/useGoToCommandHotKeys', () => ({
  useGoToCommandHotKeys: paywalled => ({
    goToCommandHotKeys: ref(
      paywalled?.value
        ? [{ id: 'goto_billing' }]
        : hotKeySources.goToCommandHotKeys
    ),
  }),
}));

vi.mock('dashboard/composables/commands/useBulkActionsHotKeys', () => ({
  useBulkActionsHotKeys: () => ({
    bulkActionsHotKeys: ref(hotKeySources.bulkActionsHotKeys),
  }),
}));

vi.mock('dashboard/composables/commands/useConversationHotKeys', () => ({
  useConversationHotKeys: () => ({
    conversationHotKeys: ref(hotKeySources.conversationHotKeys),
  }),
}));

vi.mock('dashboard/composables/commands/useMacroHotKeys', () => ({
  useMacroHotKeys: () => ({
    macroHotKeys: ref(hotKeySources.macroHotKeys),
    pendingAttributes,
    submitPendingAttributes: vi.fn(),
    dismissPendingAttributes: vi.fn(),
  }),
}));

const suggestion = {
  label: 'tomorrow',
  formattedDate: 'Feb 3, 9:00 AM',
  resolve: () => 'resolved-date',
};

vi.mock('dashboard/helper/snoozeHelpers', () => ({
  generateSnoozeSuggestions: vi.fn(search => (search ? [suggestion] : [])),
}));

class NinjaKeysStub extends HTMLElement {
  constructor() {
    super();
    this.visible = false;
    this.openedWith = null;
  }

  open(options = {}) {
    this.visible = true;
    this.openedWith = options;
  }

  close() {
    this.visible = false;
  }
}

customElements.define('ninja-keys', NinjaKeysStub);

describe('commandbar', () => {
  let wrapper;
  let element;

  const mountCommandBar = async (props = {}) => {
    wrapper = mount(CommandBar, {
      props,
      global: { stubs: { ConversationResolveAttributesModal: true } },
    });
    await flushPromises();
    element = wrapper.find('ninja-keys').element;
    return wrapper;
  };

  const commandIds = () => element.data.map(action => action.id);

  const presetSnoozeParents = () =>
    element.data
      .filter(action => action.id === 'until_tomorrow')
      .map(action => action.parent)
      .sort();

  const emitChange = async (search, actions = []) => {
    element.dispatchEvent(
      new CustomEvent('change', { detail: { search, actions } })
    );
    await flushPromises();
  };

  const emitSelected = async action => {
    element.dispatchEvent(new CustomEvent('selected', { detail: { action } }));
    await flushPromises();
  };

  const emitClosed = async () => {
    element.dispatchEvent(new CustomEvent('closed'));
    await flushPromises();
  };

  beforeEach(() => {
    dispatch.mockClear();
    track.mockClear();
  });

  afterEach(() => {
    wrapper?.unmount();
  });

  describe('command data', () => {
    it('hands every hotkey source to ninja-keys on mount', async () => {
      await mountCommandBar();

      expect(commandIds()).toEqual(
        expect.arrayContaining([
          'appearance',
          'inbox',
          'goto',
          'bulk',
          'conversation',
          'execute_a_macro',
        ])
      );
    });

    it('keeps preset snooze options while there are no dynamic suggestions', async () => {
      await mountCommandBar();

      expect(presetSnoozeParents()).toEqual([
        'bulk_action_snooze_conversation',
        'other_menu',
        'snooze_conversation',
        'snooze_notification',
      ]);
    });
  });

  describe('when the account is paywalled', () => {
    it('offers only appearance and go-to commands', async () => {
      await mountCommandBar({ isPaywalled: true });

      expect(commandIds()).toEqual(['appearance', 'goto_billing']);
    });

    it('drops inbox, bulk action and conversation commands', async () => {
      await mountCommandBar({ isPaywalled: true });

      expect(commandIds()).not.toContain('inbox');
      expect(commandIds()).not.toContain('bulk');
      expect(commandIds()).not.toContain('conversation');
    });

    it('passes the paywalled state through to the go-to commands', async () => {
      await mountCommandBar({ isPaywalled: true });

      expect(commandIds()).toContain('goto_billing');
      expect(commandIds()).not.toContain('goto');
    });
  });

  describe('placeholder', () => {
    it('asks what the user is searching for by default', async () => {
      await mountCommandBar();

      expect(element.getAttribute('placeholder')).toBe(
        'COMMAND_BAR.SEARCH_PLACEHOLDER'
      );
    });

    it('switches to the snooze prompt inside a snooze menu', async () => {
      await mountCommandBar();

      element.open({ parent: 'snooze_conversation' });
      await flushPromises();

      expect(element.getAttribute('placeholder')).toBe(
        'COMMAND_BAR.SNOOZE_PLACEHOLDER'
      );
    });
  });

  describe('dynamic snooze suggestions', () => {
    const enterSnoozeMenu = () =>
      emitChange('', [{ id: 'until_tomorrow', parent: 'snooze_conversation' }]);

    it('builds a suggestion from the search inside a snooze menu', async () => {
      await mountCommandBar();
      await enterSnoozeMenu();
      await emitChange('tomorrow');

      expect(commandIds()).toContain('dynamic_snooze_0');
    });

    it('hides the preset snooze options once a suggestion exists', async () => {
      await mountCommandBar();
      await enterSnoozeMenu();
      await emitChange('tomorrow');

      expect(presetSnoozeParents()).toEqual(['other_menu']);
      expect(commandIds()).toContain('conversation');
    });

    it('ignores the search outside a snooze menu', async () => {
      await mountCommandBar();
      await emitChange('tomorrow', [{ id: 'goto', parent: null }]);

      expect(commandIds()).not.toContain('dynamic_snooze_0');
    });

    it('clears the suggestions when the search is emptied', async () => {
      await mountCommandBar();
      await enterSnoozeMenu();
      await emitChange('tomorrow');
      await emitChange('');

      expect(commandIds()).not.toContain('dynamic_snooze_0');
      expect(commandIds()).toContain('until_tomorrow');
    });

    it('leaves the snooze menu when actions span several parents', async () => {
      await mountCommandBar();
      await enterSnoozeMenu();
      await emitChange('tomorrow', [
        { id: 'until_tomorrow', parent: 'snooze_conversation' },
        { id: 'bulk', parent: 'bulk_action_snooze_conversation' },
      ]);

      expect(commandIds()).not.toContain('dynamic_snooze_0');
    });

    it('emits the resolved date when a suggestion is picked', async () => {
      const onSnooze = vi.fn();
      emitter.on(CMD_SNOOZE_CONVERSATION, onSnooze);

      await mountCommandBar();
      await enterSnoozeMenu();
      await emitChange('tomorrow');
      element.data.find(action => action.id === 'dynamic_snooze_0').handler();

      expect(onSnooze).toHaveBeenCalledWith('resolved-date');
      emitter.off(CMD_SNOOZE_CONVERSATION, onSnooze);
    });

    it('drops the suggestions when the bar closes', async () => {
      await mountCommandBar();
      await enterSnoozeMenu();
      await emitChange('tomorrow');
      element.close();
      await flushPromises();

      expect(commandIds()).not.toContain('dynamic_snooze_0');
      expect(element.getAttribute('placeholder')).toBe(
        'COMMAND_BAR.SEARCH_PLACEHOLDER'
      );
    });
  });

  describe('selecting a command', () => {
    it('tracks the selection', async () => {
      await mountCommandBar();
      await emitSelected({
        id: 'goto',
        title: 'Go to inbox',
        section: 'General',
      });

      expect(track).toHaveBeenCalledWith(GENERAL_EVENTS.COMMAND_BAR, {
        section: 'General',
        action: 'Go to inbox',
      });
    });

    it('enters a submenu when the command has children', async () => {
      await mountCommandBar();
      await emitSelected({
        id: 'snooze_conversation',
        children: ['until_tomorrow'],
      });

      expect(element.getAttribute('placeholder')).toBe(
        'COMMAND_BAR.SNOOZE_PLACEHOLDER'
      );
    });
  });

  describe('closing the bar', () => {
    it('clears the context menu conversation', async () => {
      await mountCommandBar();
      await emitClosed();

      expect(dispatch).toHaveBeenCalledWith('setContextMenuChatId', null);
    });

    it('keeps the context menu conversation for a custom snooze', async () => {
      await mountCommandBar();
      await emitSelected({ id: 'until_custom_time' });
      await emitClosed();

      expect(dispatch).not.toHaveBeenCalled();
    });
  });
});
