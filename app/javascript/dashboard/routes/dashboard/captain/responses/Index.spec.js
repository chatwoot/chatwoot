import { flushPromises, shallowMount } from '@vue/test-utils';
import Index from './Index.vue';

const mocks = vi.hoisted(() => ({
  dispatch: vi.fn(),
  replace: vi.fn(),
  push: vi.fn(),
  getResponses: vi.fn(),
  latestImport: vi.fn(),
  createDialogOpen: vi.fn(),
  importDialogOpen: vi.fn(),
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
    props: ['buttonLabel'],
    emits: ['click', 'close'],
    template: `
      <div>
        <button data-faq-create @click="$emit('click')">{{ buttonLabel }}</button>
        <slot name="action" />
        <slot name="controls" />
        <slot name="body" />
        <slot />
      </div>
    `,
  },
}));

vi.mock('dashboard/components-next/dropdown-menu/DropdownMenu.vue', () => ({
  default: {
    props: ['menuItems'],
    emits: ['action'],
    template: `
      <div data-faq-actions>
        <button
          v-for="item in menuItems"
          :key="item.action"
          :data-faq-action="item.action"
          :disabled="item.disabled"
          @click="$emit('action', item)"
        >
          {{ item.label }}
        </button>
      </div>
    `,
  },
}));

vi.mock(
  'dashboard/components-next/captain/pageComponents/response/CreateResponseDialog.vue',
  () => ({
    default: {
      setup: (_, { expose }) => {
        const dialogRef = { open: mocks.createDialogOpen };
        expose({ dialogRef });
        return { dialogRef };
      },
      template: '<div data-create-dialog />',
    },
  })
);

vi.mock(
  'dashboard/components-next/captain/pageComponents/response/FaqImportDialog.vue',
  () => ({
    default: {
      setup: (_, { expose }) => {
        const dialogRef = { open: mocks.importDialogOpen };
        expose({ dialogRef });
        return { dialogRef };
      },
      template: '<div data-import-dialog />',
    },
  })
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
        DropdownMenu: false,
        CreateResponseDialog: false,
        FaqImportDialog: false,
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
    ['preparing', 'PREPARING'],
    ['completed', 'COMPLETED'],
    ['completed_with_errors', 'COMPLETED_WITH_ERRORS'],
    ['failed', 'FAILED'],
  ])('shows the latest %s import inline', async (status, copyKey) => {
    mocks.latestImport.mockResolvedValueOnce({
      data: {
        id: 9,
        status,
        completed_at: status === 'preparing' ? null : new Date().toISOString(),
        created_count: 2,
        overwritten_count: 1,
        skipped_count: 1,
      },
    });

    const wrapper = mountPage();
    await flushPromises();

    expect(mocks.latestImport).toHaveBeenCalledWith({ assistantId: 42 });
    expect(wrapper.get('[data-testid="faq-import-status"]').text()).toContain(
      `CAPTAIN.RESPONSES.IMPORT.STATUS.${copyKey}.TITLE`
    );
    expect(wrapper.get('[data-testid="faq-import-status"]').text()).toContain(
      'CAPTAIN.RESPONSES.IMPORT.SECTION_TITLE'
    );
    expect(
      wrapper.get('[data-testid="faq-import-status"]').attributes('data-status')
    ).toBe(status);
    await wrapper.get('[data-faq-create]').trigger('click');
    expect(wrapper.get('[data-faq-action="import"]').element.disabled).toBe(
      status === 'preparing'
    );

    wrapper.unmount();
  });

  it('does not show an import status when the assistant has no confirmed imports', async () => {
    mocks.latestImport.mockResolvedValueOnce({ data: null });

    const wrapper = mountPage();
    await flushPromises();

    expect(wrapper.find('[data-testid="faq-import-status"]').exists()).toBe(
      false
    );
    wrapper.unmount();
  });

  it('does not request import status for users who cannot manage FAQs', async () => {
    mocks.canManage = false;

    const wrapper = mountPage();
    await flushPromises();

    expect(mocks.latestImport).not.toHaveBeenCalled();
    await wrapper.get('[data-faq-create]').trigger('click');
    expect(wrapper.find('[data-faq-actions]').exists()).toBe(false);
    wrapper.unmount();
  });

  it('offers manual creation and CSV import from the create action', async () => {
    mocks.latestImport.mockResolvedValueOnce({ data: null });
    const wrapper = mountPage();
    await flushPromises();

    await wrapper.get('[data-faq-create]').trigger('click');

    expect(wrapper.get('[data-faq-action="create"]').text()).toBe(
      'CAPTAIN.RESPONSES.CREATE_MANUALLY'
    );
    expect(wrapper.get('[data-faq-action="import"]').text()).toBe(
      'CAPTAIN.RESPONSES.IMPORT.ACTION'
    );

    await wrapper.get('[data-faq-action="create"]').trigger('click');
    await flushPromises();
    expect(mocks.createDialogOpen).toHaveBeenCalledOnce();

    await wrapper.get('[data-faq-create]').trigger('click');
    await wrapper.get('[data-faq-action="import"]').trigger('click');
    await flushPromises();
    expect(mocks.importDialogOpen).toHaveBeenCalledOnce();
    wrapper.unmount();
  });

  it('refreshes FAQs when a preparing import completes', async () => {
    vi.useFakeTimers();
    mocks.latestImport
      .mockResolvedValueOnce({ data: { id: 9, status: 'preparing' } })
      .mockResolvedValueOnce({
        data: {
          id: 9,
          status: 'completed',
          completed_at: new Date().toISOString(),
        },
      });

    const wrapper = mountPage();
    await flushPromises();
    expect(mocks.getResponses).toHaveBeenCalledTimes(1);

    await vi.advanceTimersByTimeAsync(5000);
    await flushPromises();

    expect(mocks.latestImport).toHaveBeenCalledTimes(2);
    expect(mocks.getResponses).toHaveBeenCalledTimes(2);
    wrapper.unmount();
  });

  it('keeps checking an active import after a temporary status error', async () => {
    vi.useFakeTimers();
    mocks.latestImport
      .mockResolvedValueOnce({ data: { id: 9, status: 'preparing' } })
      .mockRejectedValueOnce(new Error('Unavailable'))
      .mockResolvedValueOnce({
        data: {
          id: 9,
          status: 'completed',
          completed_at: new Date().toISOString(),
        },
      });

    const wrapper = mountPage();
    await flushPromises();

    await vi.advanceTimersByTimeAsync(5000);
    await flushPromises();
    expect(mocks.latestImport).toHaveBeenCalledTimes(2);

    await vi.advanceTimersByTimeAsync(5000);
    await flushPromises();
    expect(mocks.latestImport).toHaveBeenCalledTimes(3);
    expect(
      wrapper.get('[data-testid="faq-import-status"]').attributes('data-status')
    ).toBe('completed');
    wrapper.unmount();
  });

  it('does not replace a confirmed import with an older status response', async () => {
    let resolveLatestImport;
    mocks.latestImport.mockReturnValueOnce(
      new Promise(resolve => {
        resolveLatestImport = resolve;
      })
    );

    const wrapper = mountPage();
    await wrapper.get('[data-faq-create]').trigger('click');
    await wrapper.get('[data-faq-action="import"]').trigger('click');
    await flushPromises();

    wrapper
      .findComponent({ ref: 'faqImportDialog' })
      .vm.$emit('confirmed', { id: 10, status: 'preparing' });
    await flushPromises();

    resolveLatestImport({
      data: {
        id: 9,
        status: 'completed',
        completed_at: new Date().toISOString(),
      },
    });
    await flushPromises();

    expect(
      wrapper.get('[data-testid="faq-import-status"]').attributes('data-status')
    ).toBe('preparing');
    wrapper.unmount();
  });

  it('removes a terminal import status after its display window', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-08-19T10:00:00Z'));
    mocks.latestImport.mockResolvedValueOnce({
      data: {
        id: 9,
        status: 'completed',
        completed_at: new Date().toISOString(),
      },
    });

    const wrapper = mountPage();
    await flushPromises();
    expect(wrapper.find('[data-testid="faq-import-status"]').exists()).toBe(
      true
    );

    await vi.advanceTimersByTimeAsync(15000);

    expect(wrapper.find('[data-testid="faq-import-status"]').exists()).toBe(
      false
    );
    wrapper.unmount();
  });

  it('does not restore an old terminal import status', async () => {
    mocks.latestImport.mockResolvedValueOnce({
      data: {
        id: 9,
        status: 'completed',
        completed_at: new Date(Date.now() - 16000).toISOString(),
      },
    });

    const wrapper = mountPage();
    await flushPromises();

    expect(wrapper.find('[data-testid="faq-import-status"]').exists()).toBe(
      false
    );
    wrapper.unmount();
  });
});
