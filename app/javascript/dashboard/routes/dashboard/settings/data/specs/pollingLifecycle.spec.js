import { flushPromises, mount } from '@vue/test-utils';
import { KeepAlive, defineComponent, h, nextTick, ref } from 'vue';
import DataImportsAPI from 'dashboard/api/dataImports';
import DataExportsAPI from 'dashboard/api/dataExports';
import { useAlert } from 'dashboard/composables';
import Index from '../Index.vue';
import Show from '../Show.vue';

vi.mock('dashboard/api/dataImports', () => ({
  default: {
    get: vi.fn(),
    show: vi.fn(),
  },
}));
vi.mock('dashboard/api/dataExports', () => ({ default: { get: vi.fn() } }));

vi.mock('dashboard/composables/store', () => ({
  useStoreGetters: () => ({ getCurrentAccountId: { value: 1 } }),
}));

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('vue-router', async importOriginal => ({
  ...(await importOriginal()),
  useRoute: () => ({ params: { dataImportId: 1 }, query: {} }),
  useRouter: () => ({ push: vi.fn(), replace: vi.fn() }),
}));

const deferredRequest = () => {
  let resolve;
  const promise = new Promise(resolvePromise => {
    resolve = resolvePromise;
  });
  return { promise, resolve };
};

const mountKeptAlive = component => {
  const Host = defineComponent({
    setup() {
      const visible = ref(true);
      return { visible };
    },
    render() {
      return h(KeepAlive, null, {
        default: () => (this.visible ? h(component) : null),
      });
    },
  });

  return mount(Host, {
    global: {
      stubs: {
        SettingsLayout: {
          template: '<main><slot name="header"/><slot name="body"/></main>',
        },
        BaseSettingsHeader: {
          template: '<header><slot name="actions"/></header>',
        },
        Button: {
          name: 'Button',
          props: ['label', 'disabled'],
          template: '<button :disabled="disabled">{{ label }}</button>',
        },
        Icon: true,
        TabBar: true,
        NewImportDialog: true,
        NewExportDialog: true,
        ImportDetailHeader: true,
        ImportSummaryTiles: true,
        ImportProgress: true,
        ImportErrorsSection: true,
        ImportSkipLogsSection: true,
      },
      mocks: {
        $t: key => key,
      },
    },
  });
};

describe('data import polling lifecycle', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    DataExportsAPI.get.mockResolvedValue({ data: { payload: [] } });
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.clearAllMocks();
  });

  it('explains the 30-day removal in the expired CSV file card', async () => {
    DataImportsAPI.show.mockResolvedValue({
      data: {
        id: 1,
        source_provider: 'csv',
        status: 'completed',
        artifacts_expired_at: '2026-11-13T00:00:00Z',
        skip_logs_filters: {},
      },
    });
    const wrapper = mountKeptAlive(Show);
    try {
      await flushPromises();
      expect(wrapper.text()).toContain('DATA_IMPORTS.CSV.FILE_REMOVED');
      expect(wrapper.text()).toContain('DATA_IMPORTS.CSV.FILE');
    } finally {
      wrapper.unmount();
    }
  });

  it.each(['pending', 'processing'])(
    'blocks creation during a %s contact import and re-enables it after completion',
    async status => {
      const record = { id: 1, data_type: 'contacts', status };
      DataImportsAPI.get.mockResolvedValue({
        data: { payload: [record], can_create_import: false },
      });
      const wrapper = mountKeptAlive(Index);
      try {
        await flushPromises();
        const createButton = wrapper
          .findAllComponents({ name: 'Button' })
          .find(
            button => button.props('label') === 'DATA_IMPORTS.TABLE.NEW_IMPORT'
          );
        const dialog = wrapper.findComponent({ name: 'NewImportDialog' });
        expect(createButton.props('disabled')).toBe(false);
        expect(dialog.props('hasActiveImport')).toBe(true);
        createButton.vm.$emit('click');
        await nextTick();
        expect(useAlert).toHaveBeenCalledWith(
          'DATA_IMPORTS.DRAWER.ACTIVE_IMPORT'
        );
        expect(dialog.props('show')).toBe(false);

        DataImportsAPI.get.mockResolvedValue({
          data: {
            payload: [{ ...record, status: 'completed' }],
            can_create_import: true,
          },
        });
        await vi.advanceTimersByTimeAsync(5000);
        expect(createButton.props('disabled')).toBe(false);
        expect(dialog.props('hasActiveImport')).toBe(false);
        createButton.vm.$emit('click');
        await nextTick();
        expect(dialog.props('show')).toBe(true);
      } finally {
        wrapper.unmount();
      }
    }
  );

  it('does not start list polling after the page deactivates', async () => {
    const request = deferredRequest();
    DataImportsAPI.get.mockReturnValue(request.promise);
    const wrapper = mountKeptAlive(Index);
    await nextTick();

    wrapper.vm.visible = false;
    await nextTick();
    request.resolve({ data: { payload: [{ status: 'processing' }] } });
    await flushPromises();
    await vi.advanceTimersByTimeAsync(5000);

    expect(DataImportsAPI.get).toHaveBeenCalledTimes(1);
    wrapper.unmount();
  });

  it('does not start detail polling after the page deactivates', async () => {
    const request = deferredRequest();
    DataImportsAPI.show.mockReturnValue(request.promise);
    const wrapper = mountKeptAlive(Show);
    await nextTick();

    wrapper.vm.visible = false;
    await nextTick();
    request.resolve({
      data: {
        status: 'processing',
        skip_logs_filters: {},
      },
    });
    await flushPromises();
    await vi.advanceTimersByTimeAsync(5000);

    expect(DataImportsAPI.show).toHaveBeenCalledTimes(1);
    wrapper.unmount();
  });
});
