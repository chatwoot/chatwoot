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

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch }),
  useMapGetter: key => getterValues[key],
}));

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

const captainDocument = {
  id: 42,
  name: 'FAQ source',
  external_link: 'https://example.com/docs',
  assistant: { id: 7 },
  content: 'Document content',
  pdf_document: false,
};

const DialogStub = {
  name: 'Dialog',
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

describe('DocumentDetails', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dispatch.mockResolvedValue([]);
  });

  it('requests another FAQ page when the document has more than 25 FAQs', async () => {
    const wrapper = shallowMount(DocumentDetails, {
      props: { captainDocument },
      global: {
        directives: { dompurifyHtml: {} },
        stubs: {
          Dialog: DialogStub,
          TabBar: TabBarStub,
          PaginationFooter: PaginationFooterStub,
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
});
