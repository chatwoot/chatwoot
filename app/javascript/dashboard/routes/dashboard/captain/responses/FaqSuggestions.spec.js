import { flushPromises, shallowMount } from '@vue/test-utils';
import FaqSuggestions from './FaqSuggestions.vue';

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  dispatch: vi.fn(),
  replace: vi.fn(),
  route: null,
  getterValues: null,
}));

vi.mock('dashboard/api/captain/faqSuggestions', () => ({
  default: { get: mocks.apiGet },
}));

vi.mock('dashboard/composables/store', async () => {
  const { ref } = await import('vue');
  mocks.getterValues = {
    'captainFaqSuggestions/getRecords': ref([]),
    'captainFaqSuggestions/getMeta': ref({ totalCount: 0, page: 1 }),
    'captainFaqSuggestions/getUIFlags': ref({
      fetchingList: false,
      updatingItem: false,
      deletingItem: false,
    }),
  };

  return {
    useStore: () => ({ dispatch: mocks.dispatch }),
    useMapGetter: key => mocks.getterValues[key],
  };
});

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('vue-router', async importOriginal => {
  const actual = await importOriginal();
  const { reactive } = await import('vue');
  mocks.route = reactive({
    params: { accountId: 1, assistantId: 1 },
    query: {},
  });

  return {
    ...actual,
    useRoute: () => mocks.route,
    useRouter: () => ({ replace: mocks.replace }),
  };
});

const deferred = () => {
  let resolve;
  const promise = new Promise(resolvePromise => {
    resolve = resolvePromise;
  });
  return { promise, resolve };
};

const PageLayoutStub = {
  template: '<div><slot name="body" /></div>',
};

const FaqSuggestionCardStub = {
  props: ['suggestion'],
  template: '<div>{{ suggestion.question }}</div>',
};

describe('FaqSuggestions', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.route.params.assistantId = 1;
    mocks.route.query = {};
    mocks.getterValues['captainFaqSuggestions/getRecords'].value = [];
    mocks.getterValues['captainFaqSuggestions/getMeta'].value = {
      totalCount: 0,
      page: 1,
    };
    mocks.dispatch.mockImplementation((action, payload) => {
      if (action !== 'captainFaqSuggestions/setRecords') return;

      mocks.getterValues['captainFaqSuggestions/getRecords'].value =
        payload.records;
      mocks.getterValues['captainFaqSuggestions/getMeta'].value = {
        totalCount: payload.meta.total_count,
        page: payload.meta.page,
      };
    });
  });

  it('keeps the latest assistant results when requests finish in the wrong order', async () => {
    const firstRequest = deferred();
    const secondRequest = deferred();
    mocks.apiGet
      .mockReturnValueOnce(firstRequest.promise)
      .mockReturnValueOnce(secondRequest.promise);

    const wrapper = shallowMount(FaqSuggestions, {
      global: {
        mocks: { $t: key => key },
        stubs: {
          PageLayout: PageLayoutStub,
          FaqSuggestionCard: FaqSuggestionCardStub,
        },
      },
    });

    await flushPromises();
    mocks.route.params.assistantId = 2;
    await flushPromises();

    secondRequest.resolve({
      data: {
        payload: [{ id: 2, question: 'Current assistant' }],
        meta: { page: 1, total_count: 1 },
      },
    });
    await flushPromises();

    firstRequest.resolve({
      data: {
        payload: [{ id: 1, question: 'Previous assistant' }],
        meta: { page: 1, total_count: 1 },
      },
    });
    await flushPromises();

    expect(wrapper.text()).toContain('Current assistant');
    expect(wrapper.text()).not.toContain('Previous assistant');

    wrapper.unmount();
  });
});
