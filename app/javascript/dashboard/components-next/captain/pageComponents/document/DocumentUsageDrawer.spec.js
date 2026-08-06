import { flushPromises, mount } from '@vue/test-utils';
import CaptainDocumentAPI from 'dashboard/api/captain/document';
import DocumentUsageDrawer from './DocumentUsageDrawer.vue';

vi.mock('dashboard/api/captain/document', () => ({
  default: {
    getDrilldown: vi.fn(),
  },
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, { n } = {}) => {
      if (key === 'CAPTAIN.DOCUMENTS.USED_IN_CONVERSATIONS') {
        return `Used in ${n} ${n === 1 ? 'conversation' : 'conversations'}`;
      }
      return key;
    },
  }),
}));

const payload = [
  {
    record_type: 'conversation',
    conversation: { id: 10, display_id: 42 },
    message: null,
    occurred_at: 1_700_000_000,
  },
];

const SidePanelStub = {
  name: 'SidePanel',
  methods: { open() {}, close() {} },
  emits: ['close'],
  template:
    '<section><slot name="header" /><slot /><button data-test="close" @click="$emit(\'close\')" /></section>',
};

const mountDrawer = async () => {
  const wrapper = mount(DocumentUsageDrawer, {
    props: {
      open: false,
      document: {
        id: 7,
        name: 'Returns and refunds',
        used_in_conversations_count: 1,
      },
    },
    global: {
      stubs: {
        SidePanel: SidePanelStub,
        Spinner: true,
        Button: {
          props: ['label'],
          template: '<button>{{ label }}</button>',
        },
        ReportDrilldownCard: {
          props: ['record'],
          template:
            '<div data-test="conversation-card">#{{ record.conversation.display_id }}</div>',
        },
      },
      mocks: { $t: key => key },
    },
  });
  await wrapper.setProps({ open: true });
  return wrapper;
};

describe('DocumentUsageDrawer', () => {
  beforeEach(() => {
    CaptainDocumentAPI.getDrilldown.mockResolvedValue({
      data: {
        meta: { current_page: 1, total_count: 1, conversation_count: 1 },
        payload,
      },
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('loads the document conversations through the shared drilldown contract', async () => {
    const wrapper = await mountDrawer();
    await flushPromises();

    expect(CaptainDocumentAPI.getDrilldown).toHaveBeenCalledWith(
      expect.objectContaining({ documentId: 7, page: 1 })
    );
    expect(wrapper.text()).toContain('Returns and refunds');
    expect(wrapper.text()).toContain('Used in 1 conversation');
    expect(wrapper.get('[data-test="conversation-card"]').text()).toBe('#42');
  });

  it('emits close when the shared side panel closes', async () => {
    const wrapper = await mountDrawer();
    await flushPromises();

    await wrapper.get('[data-test="close"]').trigger('click');

    expect(wrapper.emitted('close')).toBeTruthy();
  });
});
