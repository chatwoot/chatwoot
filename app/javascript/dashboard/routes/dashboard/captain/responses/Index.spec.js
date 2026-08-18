import { flushPromises, shallowMount } from '@vue/test-utils';
import Index from './Index.vue';

const mocks = vi.hoisted(() => ({
  dispatch: vi.fn(),
  replace: vi.fn(),
  push: vi.fn(),
  getResponses: vi.fn(),
  latestImport: vi.fn(),
  canManage: true,
  getterValues: null,
}));

vi.mock('dashboard/api/captain/response', () => ({
  default: { get: mocks.getResponses, getDrilldown: vi.fn() },
}));

vi.mock('dashboard/api/captain/faqImports', () => ({
  default: { latest: mocks.latestImport },
}));

vi.mock('dashboard/components-next/captain/PageLayout.vue', () => ({
  default: {
    template: `
      <div>
        <slot name="headerActions" />
        <slot name="controls" />
        <slot name="body" />
        <slot />
      </div>
    `,
  },
}));

vi.mock('dashboard/components-next/banner/Banner.vue', () => ({
  default: {
    props: ['color'],
    template: '<div data-banner :data-color="color"><slot /></div>',
  },
}));

vi.mock('dashboard/components-next/button/Button.vue', () => ({
  default: {
    props: ['label', 'disabled'],
    template:
      '<button :data-button="label" :disabled="disabled">{{ label }}</button>',
  },
}));

vi.mock('dashboard/components/policy.vue', () => ({
  default: { template: '<div><slot /></div>' },
}));

vi.mock('dashboard/components-next/input/Input.vue', () => ({
  default: { template: '<div />' },
}));

vi.mock(
  'dashboard/components-next/captain/assistant/BulkSelectBar.vue',
  () => ({ default: { template: '<div />' } })
);

vi.mock(
  'dashboard/components-next/captain/pageComponents/DeleteDialog.vue',
  () => ({ default: { template: '<div />' } })
);

vi.mock(
  'dashboard/components-next/captain/pageComponents/BulkDeleteDialog.vue',
  () => ({ default: { template: '<div />' } })
);

vi.mock('dashboard/components-next/captain/pageComponents/Paywall.vue', () => ({
  default: { template: '<div />' },
}));

vi.mock('dashboard/components-next/captain/assistant/ResponseCard.vue', () => ({
  default: { template: '<div />' },
}));

vi.mock(
  'dashboard/components-next/captain/pageComponents/response/CreateResponseDialog.vue',
  () => ({ default: { template: '<div />' } })
);

vi.mock(
  'dashboard/components-next/captain/pageComponents/emptyStates/ResponsePageEmptyState.vue',
  () => ({ default: { template: '<div />' } })
);

vi.mock(
  'dashboard/components-next/feature-spotlight/FeatureSpotlightPopover.vue',
  () => ({ default: { template: '<div />' } })
);

vi.mock(
  'dashboard/components-next/captain/pageComponents/response/LimitBanner.vue',
  () => ({ default: { template: '<div />' } })
);

vi.mock(
  'dashboard/components-next/captain/pageComponents/ConversationUsageDrawer.vue',
  () => ({ default: { template: '<div />' } })
);

vi.mock(
  'dashboard/components-next/captain/pageComponents/response/FaqImportDialog.vue',
  () => ({ default: { template: '<div />' } })
);

vi.mock('dashboard/composables/store', async () => {
  const { ref } = await import('vue');
  mocks.getterValues = {
    'captainResponses/getUIFlags': ref({ fetchingList: false }),
    'captainResponses/getMeta': ref({ totalCount: 0, page: 1 }),
    'captainResponses/getRecords': ref([]),
    'captainFaqSuggestions/getOpenCount': ref(0),
  };

  return {
    useStore: () => ({ dispatch: mocks.dispatch }),
    useMapGetter: key => mocks.getterValues[key],
  };
});

vi.mock('dashboard/composables/useAccount', async () => {
  const { ref } = await import('vue');
  return { useAccount: () => ({ isOnChatwootCloud: ref(false) }) };
});

vi.mock('dashboard/composables/usePolicy', () => ({
  usePolicy: () => ({ checkPermissions: () => mocks.canManage }),
}));

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('vue-router', async importOriginal => {
  const actual = await importOriginal();
  const { reactive } = await import('vue');
  const route = reactive({
    params: { accountId: 1, assistantId: 42 },
    query: {},
  });

  return {
    ...actual,
    useRoute: () => route,
    useRouter: () => ({ replace: mocks.replace, push: mocks.push }),
  };
});

const mountPage = () =>
  shallowMount(Index, {
    global: {
      mocks: { $t: key => key },
      stubs: {
        PageLayout: false,
        Banner: false,
        Button: false,
        Policy: false,
      },
    },
  });

describe('Captain FAQ imports on the responses page', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.canManage = true;
    mocks.getResponses.mockResolvedValue({
      data: { payload: [], meta: { page: 1, total_count: 0 } },
    });
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it.each([
    ['preparing', 'blue', 'PREPARING'],
    ['completed', 'teal', 'COMPLETED'],
    ['completed_with_errors', 'amber', 'COMPLETED_WITH_ERRORS'],
    ['failed', 'ruby', 'FAILED'],
  ])('shows the latest %s import inline', async (status, color, copyKey) => {
    mocks.latestImport.mockResolvedValueOnce({
      data: {
        id: 9,
        status,
        created_count: 2,
        overwritten_count: 1,
        skipped_count: 1,
      },
    });

    const wrapper = mountPage();
    await flushPromises();

    expect(mocks.latestImport).toHaveBeenCalledWith({ assistantId: 42 });
    expect(wrapper.get('[data-banner]').attributes('data-color')).toBe(color);
    expect(wrapper.get('[data-banner]').text()).toContain(
      `CAPTAIN.RESPONSES.IMPORT.STATUS.${copyKey}.TITLE`
    );
    expect(
      wrapper.get('[data-button="CAPTAIN.RESPONSES.IMPORT.ACTION"]').element
        .disabled
    ).toBe(status === 'preparing');

    wrapper.unmount();
  });

  it('does not show an import status when the assistant has no confirmed imports', async () => {
    mocks.latestImport.mockResolvedValueOnce({ data: null });

    const wrapper = mountPage();
    await flushPromises();

    expect(wrapper.find('[data-banner]').exists()).toBe(false);
    wrapper.unmount();
  });

  it('does not request import status for users who cannot manage FAQs', async () => {
    mocks.canManage = false;

    const wrapper = mountPage();
    await flushPromises();

    expect(mocks.latestImport).not.toHaveBeenCalled();
    expect(
      wrapper.find('[data-button="CAPTAIN.RESPONSES.IMPORT.ACTION"]').exists()
    ).toBe(false);
    wrapper.unmount();
  });

  it('refreshes FAQs when a preparing import completes', async () => {
    vi.useFakeTimers();
    mocks.latestImport
      .mockResolvedValueOnce({ data: { id: 9, status: 'preparing' } })
      .mockResolvedValueOnce({ data: { id: 9, status: 'completed' } });

    const wrapper = mountPage();
    await flushPromises();
    expect(mocks.getResponses).toHaveBeenCalledTimes(1);

    await vi.advanceTimersByTimeAsync(5000);
    await flushPromises();

    expect(mocks.latestImport).toHaveBeenCalledTimes(2);
    expect(mocks.getResponses).toHaveBeenCalledTimes(2);
    wrapper.unmount();
  });
});
