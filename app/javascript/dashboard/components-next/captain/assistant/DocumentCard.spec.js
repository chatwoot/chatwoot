import { shallowMount } from '@vue/test-utils';
import DocumentCard from './DocumentCard.vue';

const { checkPermissions } = vi.hoisted(() => ({
  checkPermissions: vi.fn(() => true),
}));

vi.mock('dashboard/composables/usePolicy', () => ({
  usePolicy: () => ({ checkPermissions }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, { n } = {}) => {
      if (key === 'CAPTAIN.DOCUMENTS.FAQ_COUNT') return `${n} FAQs`;
      if (key === 'CAPTAIN.DOCUMENTS.USED_IN_CONVERSATIONS') {
        return `Used in ${n} conversations`;
      }
      return key;
    },
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
  shallowMount(DocumentCard, {
    props: {
      id: 42,
      name: 'Returns and refunds',
      assistant: { name: 'Acme assistant' },
      externalLink:
        'https://example.com/help/articles/refund-and-return-policy-for-online-orders',
      createdAt: 1_700_000_000,
      status: 'available',
      responsesCount: 12,
      usedInConversationsCount: 8,
      ...props,
    },
    global: {
      directives: { onClickaway: {} },
      stubs: {
        Button: ButtonStub,
        CardLayout: { template: '<div><slot /></div>' },
        DocumentSyncStatus: true,
        DropdownMenu: true,
        Checkbox: true,
        Icon: true,
      },
    },
  });

describe('DocumentCard', () => {
  beforeEach(() => {
    checkPermissions.mockReturnValue(true);
  });

  it('shows a compact conversation count after the FAQ count', () => {
    const wrapper = mountCard();
    const usageButton = wrapper.get('[aria-label="Used in 8 conversations"]');

    expect(usageButton.text()).toBe('8');
    expect(usageButton.attributes('slate')).toBe('');
    expect(usageButton.element.previousElementSibling.textContent).toContain(
      '12 FAQs'
    );
  });

  it('opens the document conversation drilldown from the compact count', async () => {
    const wrapper = mountCard();

    await wrapper
      .get('[aria-label="Used in 8 conversations"]')
      .trigger('click');

    expect(wrapper.emitted('viewConversations')).toEqual([[42]]);
  });

  it('shows zero usage as disabled metadata', () => {
    const wrapper = mountCard({ usedInConversationsCount: 0 });
    const usageButton = wrapper.get('[aria-label="Used in 0 conversations"]');

    expect(usageButton.text()).toBe('0');
    expect(usageButton.attributes('disabled')).toBeDefined();
  });

  it('keeps the source URL flexible and the metadata row on one line', () => {
    const wrapper = mountCard();
    const sourceLink = wrapper.get('a[href^="https://example.com"]');
    const metadataRow = sourceLink.element.parentElement;

    expect(sourceLink.classes()).toContain('flex-1');
    expect(sourceLink.classes()).toContain('truncate');
    expect(metadataRow.classList).not.toContain('flex-wrap');
  });

  it('hides usage analytics from users who cannot manage the assistant', () => {
    checkPermissions.mockReturnValue(false);
    const wrapper = mountCard();

    expect(
      wrapper.find('[aria-label="Used in 8 conversations"]').exists()
    ).toBe(false);
  });
});
