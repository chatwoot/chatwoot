import { flushPromises, mount } from '@vue/test-utils';
import { KeepAlive, defineComponent, h, nextTick, ref } from 'vue';
import DataImportsAPI from 'dashboard/api/dataImports';
import Index from '../Index.vue';
import Show from '../Show.vue';

vi.mock('dashboard/api/dataImports', () => ({
  default: {
    get: vi.fn(),
    show: vi.fn(),
  },
}));

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
  useRoute: () => ({ params: { dataImportId: 1 } }),
  useRouter: () => ({ push: vi.fn() }),
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
        SettingsLayout: true,
        BaseSettingsHeader: true,
        Button: true,
        Icon: true,
        TabBar: true,
        NewImportDialog: true,
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
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.clearAllMocks();
  });

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
