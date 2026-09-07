import { shallowMount } from '@vue/test-utils';
import ResponseCard from './ResponseCard.vue';

const { checkPermissions } = vi.hoisted(() => ({
  checkPermissions: vi.fn(() => true),
}));

vi.mock('dashboard/composables/usePolicy', () => ({
  usePolicy: () => ({ checkPermissions }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, { n } = {}) => {
      if (key === 'CAPTAIN.DOCUMENTS.USED_IN_CONVERSATIONS') {
        return `Used in ${n} conversations`;
      }
      return key;
    },
    locale: { value: 'en' },
  }),
}));

const ButtonStub = {
  inheritAttrs: false,
  props: ['label', 'disabled'],
  emits: ['click'],
  template:
    '<button v-bind="$attrs" :disabled="disabled" @click="$emit(\'click\', $event)">{{ label }}</button>',
};

const mountCard = (props = {}) =>
  shallowMount(ResponseCard, {
    props: {
      id: 42,
      question: 'How long do refunds take?',
      answer: 'Refunds take five business days.',
      assistant: { name: 'Acme assistant' },
      documentable: {
        id: 1,
        type: 'User',
        available_name: 'John',
      },
      createdAt: 1_700_000_000,
      updatedAt: 1_700_000_000,
      usedInConversationsCount: 4,
      ...props,
    },
    global: {
      directives: { onClickaway: {} },
      stubs: {
        Button: ButtonStub,
        CardLayout: { template: '<div><slot /></div>' },
        Policy: { template: '<div><slot /></div>' },
        DropdownMenu: true,
        Checkbox: true,
        Icon: true,
      },
    },
  });

describe('ResponseCard', () => {
  beforeEach(() => {
    checkPermissions.mockReturnValue(true);
  });

  it('opens conversation usage for a user-created FAQ', async () => {
    const wrapper = mountCard();
    const usageButton = wrapper.get('[aria-label="Used in 4 conversations"]');

    expect(usageButton.text()).toBe('4');
    await usageButton.trigger('click');
    expect(wrapper.emitted('viewConversations')).toEqual([[42]]);
  });

  it('shows zero usage as disabled metadata', () => {
    const wrapper = mountCard({ usedInConversationsCount: 0 });
    const usageButton = wrapper.get('[aria-label="Used in 0 conversations"]');

    expect(usageButton.text()).toBe('0');
    expect(usageButton.attributes('disabled')).toBeDefined();
  });

  it('does not show usage for an FAQ without a user source', () => {
    const wrapper = mountCard({
      documentable: null,
      usedInConversationsCount: 4,
    });

    expect(wrapper.find('[aria-label^="Used in"]').exists()).toBe(false);
  });

  it('hides usage analytics from users who cannot manage the assistant', () => {
    checkPermissions.mockReturnValue(false);
    const wrapper = mountCard();

    expect(wrapper.find('[aria-label^="Used in"]').exists()).toBe(false);
  });
});
