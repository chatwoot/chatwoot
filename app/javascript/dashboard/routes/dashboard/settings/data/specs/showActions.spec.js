import { flushPromises, mount } from '@vue/test-utils';
import { KeepAlive, defineComponent, h, nextTick } from 'vue';
import { useAlert } from 'dashboard/composables';
import DataImportsAPI from 'dashboard/api/dataImports';
import Show from '../Show.vue';
import { POLL_INTERVAL_MS } from '../importStatus';

vi.mock('dashboard/api/dataImports', () => ({
  default: {
    show: vi.fn(),
    retry: vi.fn(),
  },
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
}));

const SettingsLayoutStub = {
  template: `
    <main>
      <slot name="header" />
      <slot name="body" />
    </main>
  `,
};

const ImportDetailHeaderStub = {
  name: 'ImportDetailHeader',
  props: {
    dataImport: {
      type: Object,
      default: null,
    },
  },
  emits: ['retry'],
  template: `
    <button
      v-if="dataImport?.stalled"
      data-test="retry"
      @click="$emit('retry')"
    />
  `,
};

const deferredRequest = () => {
  let resolve;
  const promise = new Promise(resolvePromise => {
    resolve = resolvePromise;
  });
  return { promise, resolve };
};

const mountShow = () => {
  const Host = defineComponent({
    render() {
      return h(KeepAlive, null, { default: () => h(Show) });
    },
  });

  return mount(Host, {
    global: {
      stubs: {
        SettingsLayout: SettingsLayoutStub,
        ImportDetailHeader: ImportDetailHeaderStub,
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

describe('data import detail actions', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    DataImportsAPI.show.mockResolvedValue({
      data: {
        id: 1,
        status: 'processing',
        stalled: true,
        skip_logs_filters: {},
      },
    });
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.clearAllMocks();
  });

  it('retries a stalled import and replaces the page state', async () => {
    DataImportsAPI.retry.mockResolvedValue({
      data: {
        id: 1,
        status: 'pending',
        stalled: false,
        skip_logs_filters: {},
      },
    });
    const wrapper = mountShow();
    await nextTick();
    await flushPromises();

    await wrapper.find('[data-test="retry"]').trigger('click');
    await flushPromises();

    expect(DataImportsAPI.retry).toHaveBeenCalledWith(1);
    expect(useAlert).toHaveBeenCalledWith('DATA_IMPORTS.ALERTS.IMPORT_RETRIED');
    wrapper.unmount();
  });

  it('ignores an older poll response after retry succeeds', async () => {
    const pollRequest = deferredRequest();
    DataImportsAPI.retry.mockResolvedValue({
      data: {
        id: 1,
        status: 'pending',
        stalled: false,
        skip_logs_filters: {},
      },
    });
    const wrapper = mountShow();
    await nextTick();
    await flushPromises();

    DataImportsAPI.show.mockReturnValueOnce(pollRequest.promise);
    await vi.advanceTimersByTimeAsync(POLL_INTERVAL_MS);
    expect(DataImportsAPI.show).toHaveBeenCalledTimes(2);

    await wrapper.find('[data-test="retry"]').trigger('click');
    await flushPromises();
    expect(wrapper.find('[data-test="retry"]').exists()).toBe(false);

    pollRequest.resolve({
      data: {
        id: 1,
        status: 'processing',
        stalled: true,
        skip_logs_filters: {},
      },
    });
    await flushPromises();

    expect(wrapper.find('[data-test="retry"]').exists()).toBe(false);
    wrapper.unmount();
  });
});
