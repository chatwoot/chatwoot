import { flushPromises, shallowMount } from '@vue/test-utils';
import DocumentDetails from './DocumentDetails.vue';

const { dispatch, getDrilldown, getterValues } = vi.hoisted(() => ({
  dispatch: vi.fn(),
  getDrilldown: vi.fn(),
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
vi.mock('dashboard/api/captain/document', () => ({
  default: { getDrilldown },
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
  props: ['tabs'],
  template: `
    <div>
      <button data-test="faq-tab" @click="$emit('tabChanged', { key: 'faqs' })" />
      <button
        v-if="tabs.some(tab => tab.key === 'usage')"
        data-test="usage-tab"
        @click="$emit('tabChanged', { key: 'usage' })"
      />
    </div>
  `,
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
    getDrilldown.mockResolvedValue({
      data: {
        meta: { current_page: 1, total_count: 1, conversation_count: 1 },
        payload: [
          {
            record_type: 'conversation',
            conversation: { id: 10, display_id: 77 },
            message: null,
            occurred_at: 1_700_000_000,
          },
        ],
      },
    });
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
          ReportDrilldownCard: {
            props: ['record'],
            template:
              '<div data-test="conversation-card">#{{ record.conversation.display_id }}</div>',
          },
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

  it('loads document usage in the third details tab', async () => {
    const wrapper = shallowMount(DocumentDetails, {
      props: { captainDocument },
      global: {
        directives: { dompurifyHtml: {} },
        stubs: {
          SidePanel: SidePanelStub,
          TabBar: TabBarStub,
          PaginationFooter: PaginationFooterStub,
          Button: ButtonStub,
          ReportDrilldownCard: {
            props: ['record'],
            template:
              '<div data-test="conversation-card">#{{ record.conversation.display_id }}</div>',
          },
        },
      },
    });

    expect(wrapper.getComponent(TabBarStub).props('tabs')).toEqual([
      {
        key: 'content',
        label: 'CAPTAIN.DOCUMENTS.DETAILS.CONTENT_TAB',
      },
      {
        key: 'faqs',
        label: 'CAPTAIN.DOCUMENTS.RELATED_RESPONSES.TITLE',
        count: 26,
      },
      {
        key: 'usage',
        label: 'CAPTAIN.DOCUMENTS.DETAILS.USED_IN_CONVERSATIONS',
        count: 8,
      },
    ]);

    await wrapper.get('[data-test="usage-tab"]').trigger('click');
    await flushPromises();

    expect(getDrilldown).toHaveBeenCalledWith(
      expect.objectContaining({ documentId: 42, page: 1 })
    );
    expect(wrapper.get('[data-test="conversation-card"]').text()).toBe('#77');
    expect(wrapper.emitted('viewConversations')).toBeUndefined();
  });

  it('hides the document usage tab from users who cannot manage the assistant', () => {
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
          ReportDrilldownCard: true,
        },
      },
    });

    expect(wrapper.find('[data-test="usage-tab"]').exists()).toBe(false);
  });
});
