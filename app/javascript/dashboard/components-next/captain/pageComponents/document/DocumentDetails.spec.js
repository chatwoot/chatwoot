import { flushPromises, shallowMount } from '@vue/test-utils';
import DocumentDetails from './DocumentDetails.vue';

const { dispatch, getterValues } = vi.hoisted(() => ({
  dispatch: vi.fn(),
  getterValues: {
    'captainResponses/getUIFlags': { value: { fetchingList: false } },
    'captainResponses/getRecords': { value: [] },
    'captainResponses/getMeta': { value: { totalCount: 26, page: 1 } },
  },
}));

const { checkPermissions } = vi.hoisted(() => ({
  checkPermissions: vi.fn(() => true),
}));

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch }),
  useMapGetter: key => getterValues[key],
}));

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
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
  }),
}));

const captainDocument = {
  id: 42,
  name: 'FAQ source',
  external_link: 'https://example.com/docs',
  assistant: { id: 7 },
  content: 'Document content',
  pdf_document: false,
  used_in_conversations_count: 8,
};

const SidePanelStub = {
  name: 'SidePanel',
  methods: { open() {}, close() {} },
  template: '<div><slot /></div>',
};

const TabBarStub = {
  name: 'TabBar',
  template:
    '<button data-test="faq-tab" @click="$emit(\'tabChanged\', { key: \'faqs\' })" />',
};

const PaginationFooterStub = {
  name: 'PaginationFooter',
  template:
    '<button data-test="next-page" @click="$emit(\'update:currentPage\', 2)" />',
};

const ButtonStub = {
  inheritAttrs: false,
  props: ['label', 'disabled'],
  emits: ['click'],
  template:
    '<button v-bind="$attrs" :disabled="disabled" @click="$emit(\'click\', $event)">{{ label }}</button>',
};

describe('DocumentDetails', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dispatch.mockResolvedValue([]);
    checkPermissions.mockReturnValue(true);
  });

  it('requests another FAQ page when the document has more than 25 FAQs', async () => {
    const wrapper = shallowMount(DocumentDetails, {
      props: { captainDocument },
      global: {
        directives: { dompurifyHtml: {} },
        stubs: {
          SidePanel: SidePanelStub,
          TabBar: TabBarStub,
          PaginationFooter: PaginationFooterStub,
          Button: ButtonStub,
        },
      },
    });

    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith('captainResponses/get', {
      page: 1,
      assistantId: 7,
      documentId: 42,
    });

    await wrapper.get('[data-test="faq-tab"]').trigger('click');
    await wrapper.get('[data-test="next-page"]').trigger('click');

    expect(dispatch).toHaveBeenLastCalledWith('captainResponses/get', {
      page: 2,
      assistantId: 7,
      documentId: 42,
    });
  });

  it('shows document usage in the details metadata and opens its conversations', async () => {
    const wrapper = shallowMount(DocumentDetails, {
      props: { captainDocument },
      global: {
        directives: { dompurifyHtml: {} },
        stubs: {
          SidePanel: SidePanelStub,
          TabBar: TabBarStub,
          PaginationFooter: PaginationFooterStub,
          Button: ButtonStub,
        },
      },
    });

    const usageButton = wrapper.get('[aria-label="Used in 8 conversations"]');
    expect(usageButton.text()).toBe('8');

    await usageButton.trigger('click');

    expect(wrapper.emitted('viewConversations')).toEqual([[42]]);
  });

  it('hides document usage from users who cannot manage the assistant', () => {
    checkPermissions.mockReturnValue(false);

    const wrapper = shallowMount(DocumentDetails, {
      props: { captainDocument },
      global: {
        directives: { dompurifyHtml: {} },
        stubs: {
          SidePanel: SidePanelStub,
          TabBar: TabBarStub,
          PaginationFooter: PaginationFooterStub,
          Button: ButtonStub,
        },
      },
    });

    expect(wrapper.find('[aria-label^="Used in"]').exists()).toBe(false);
  });
});
