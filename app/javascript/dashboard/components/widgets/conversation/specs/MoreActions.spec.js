import { ref } from 'vue';
import { flushPromises, mount } from '@vue/test-utils';
import { useAlert } from 'dashboard/composables';
import { createStore } from 'vuex';
import MoreActions from '../MoreActions.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => key,
  }),
}));

// vitest loads @vueuse/core with its own copy of Vue, so its refs would not re-render the menu.
vi.mock('@vueuse/core', () => ({
  useToggle: () => {
    const value = ref(false);
    const toggle = next => {
      value.value = typeof next === 'boolean' ? next : !value.value;
    };
    return [value, toggle];
  },
}));

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

const DropdownMenuStub = {
  props: { menuItems: { type: Array, default: () => [] } },
  emits: ['action'],
  template: `
    <div>
      <button
        v-for="item in menuItems"
        :key="item.action"
        :data-action="item.action"
        @click="$emit('action', item)"
      >
        {{ item.label }}
        <slot name="trailing-icon" :item="item" />
      </button>
    </div>
  `,
};

const mountMoreActions = ({ autoTranslate, setAutoTranslate = vi.fn() }) => {
  const store = createStore({
    getters: {
      getSelectedChat: () => ({ id: 1, status: 'open', muted: false }),
      getAutoTranslate: () => ({
        enabled: true,
        language: 'Turkish',
        disabledInConversation: false,
        ...autoTranslate,
      }),
    },
    actions: { setConversationAutoTranslate: setAutoTranslate },
  });

  return mount(MoreActions, {
    global: {
      plugins: [store],
      mocks: { $t: key => key },
      directives: { onClickaway: {}, tooltip: {} },
      stubs: {
        ResolveAction: true,
        EmailTranscriptModal: true,
        ButtonV4: { template: '<button data-more />' },
        DropdownMenu: DropdownMenuStub,
      },
    },
  });
};

const openMenu = async wrapper => {
  await wrapper.find('[data-more]').trigger('click');
};

describe('MoreActions auto-translate switch', () => {
  beforeEach(() => {
    useAlert.mockClear();
  });

  it('offers to turn it off and names the language replies are sent in', async () => {
    const wrapper = mountMoreActions({});
    await openMenu(wrapper);

    const item = wrapper.find('[data-action="auto_translate"]');
    expect(item.text()).toBe(
      'CONVERSATION.HEADER.AUTO_TRANSLATE.TURN_OFF Turkish'
    );
  });

  it('turns it off for the conversation', async () => {
    const setAutoTranslate = vi.fn();
    const wrapper = mountMoreActions({ setAutoTranslate });
    await openMenu(wrapper);

    await wrapper.find('[data-action="auto_translate"]').trigger('click');
    await flushPromises();

    expect(setAutoTranslate).toHaveBeenCalledWith(expect.anything(), {
      conversationId: 1,
      disabled: true,
    });
    expect(useAlert).toHaveBeenCalledWith(
      'CONVERSATION.HEADER.AUTO_TRANSLATE.TURNED_OFF'
    );
  });

  it('turns it back on once it is off', async () => {
    const setAutoTranslate = vi.fn();
    const wrapper = mountMoreActions({
      autoTranslate: { disabledInConversation: true },
      setAutoTranslate,
    });
    await openMenu(wrapper);

    const item = wrapper.find('[data-action="auto_translate"]');
    expect(item.text()).toBe('CONVERSATION.HEADER.AUTO_TRANSLATE.TURN_ON');

    await item.trigger('click');
    await flushPromises();

    expect(setAutoTranslate).toHaveBeenCalledWith(expect.anything(), {
      conversationId: 1,
      disabled: false,
    });
    expect(useAlert).toHaveBeenCalledWith(
      'CONVERSATION.HEADER.AUTO_TRANSLATE.TURNED_ON'
    );
  });

  it('tells the agent when the change could not be saved', async () => {
    const wrapper = mountMoreActions({
      setAutoTranslate: vi.fn().mockRejectedValue(new Error('Failed')),
    });
    await openMenu(wrapper);

    await wrapper.find('[data-action="auto_translate"]').trigger('click');
    await flushPromises();

    expect(useAlert).toHaveBeenCalledWith(
      'CONVERSATION.HEADER.AUTO_TRANSLATE.UPDATE_FAILED'
    );
  });

  it('hides the switch while auto-translate is off for the account', async () => {
    const wrapper = mountMoreActions({ autoTranslate: { enabled: false } });
    await openMenu(wrapper);

    expect(wrapper.find('[data-action="auto_translate"]').exists()).toBe(false);
  });
});
