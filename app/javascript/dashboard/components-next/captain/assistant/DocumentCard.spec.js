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

  it('keeps the source URL flexible and the metadata row on one line', () => {
    const wrapper = mountCard();
    const sourceLink = wrapper.get('a[href^="https://example.com"]');
    const metadataRow = sourceLink.element.parentElement;

    expect(sourceLink.classes()).toContain('flex-1');
    expect(sourceLink.classes()).toContain('truncate');
    expect(metadataRow.classList).not.toContain('flex-wrap');
  });

  it('keeps conversation usage out of the document card', () => {
    const wrapper = mountCard();

    expect(wrapper.find('[aria-label^="Used in"]').exists()).toBe(false);
  });

  it('opens details from the document title without a separate action', async () => {
    const wrapper = mountCard();
    const titleButton = wrapper
      .findAll('button')
      .find(button => button.text() === 'Returns and refunds');

    expect(titleButton).toBeDefined();
    expect(wrapper.text()).not.toContain('View details');
    await titleButton.trigger('click');

    expect(wrapper.emitted('action')).toEqual([
      [{ action: 'viewDetails', id: 42 }],
    ]);
  });
});
