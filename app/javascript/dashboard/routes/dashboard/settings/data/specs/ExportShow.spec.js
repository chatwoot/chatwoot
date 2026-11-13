import { flushPromises, mount } from '@vue/test-utils';
import { KeepAlive } from 'vue';
import DataExportsAPI from 'dashboard/api/dataExports';
import ExportShow from '../ExportShow.vue';

const replace = vi.hoisted(() => vi.fn());
vi.mock('vue-router', async importOriginal => ({
  ...(await importOriginal()),
  useRoute: () => ({ params: { accountId: 1, dataExportId: 7 } }),
  useRouter: () => ({ replace }),
}));
vi.mock('dashboard/api/dataExports', () => ({
  default: { show: vi.fn(), rerun: vi.fn() },
}));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));

const mountDetail = () => {
  return mount(
    {
      components: { KeepAlive, ExportShow },
      template: '<KeepAlive><ExportShow /></KeepAlive>',
    },
    {
      global: {
        stubs: {
          SettingsLayout: {
            template: '<main><slot name="header"/><slot name="body"/></main>',
          },
          BaseSettingsHeader: {
            template: '<header><slot name="title"/></header>',
          },
          Button: {
            props: ['label'],
            template: '<button>{{ label }}</button>',
          },
          Icon: true,
        },
        mocks: { $t: key => key },
      },
    }
  );
};

describe('export reruns', () => {
  it('pauses refreshes on the stalled run until the new detail page opens', async () => {
    vi.useFakeTimers();
    const record = {
      id: 7,
      status: 'processing',
      can_rerun: true,
      processed_records: 0,
      export_options: {},
    };
    DataExportsAPI.show.mockResolvedValue({ data: record });
    let finishRerun;
    DataExportsAPI.rerun.mockReturnValue(
      new Promise(resolve => {
        finishRerun = resolve;
      })
    );
    const wrapper = mountDetail();
    try {
      await flushPromises();
      await wrapper
        .findAll('button')
        .find(button => button.text() === 'DATA_EXPORTS.RERUN')
        .trigger('click');
      await vi.advanceTimersByTimeAsync(5000);
      expect(DataExportsAPI.show).toHaveBeenCalledTimes(1);
      finishRerun({ data: { ...record, id: 8 } });
      await flushPromises();
      expect(replace).toHaveBeenCalledWith({
        name: 'settings_data_export_show',
        params: { accountId: 1, dataExportId: 8 },
      });
    } finally {
      wrapper.unmount();
      vi.useRealTimers();
    }
  });
});

describe('export detail loading', () => {
  let wrapper;
  const record = {
    id: 7,
    name: 'Contacts export',
    status: 'processing',
    processed_records: 42,
    total_records: 100,
    export_options: {},
  };

  beforeEach(() => {
    vi.useFakeTimers();
    vi.clearAllMocks();
  });

  afterEach(() => {
    wrapper?.unmount();
    vi.useRealTimers();
  });

  it.each(['pending', 'processing'])(
    'stops polling a stalled %s export and resumes after a manual refresh',
    async status => {
      const activeRecord = { ...record, status, stalled: false };
      DataExportsAPI.show
        .mockResolvedValueOnce({ data: activeRecord })
        .mockResolvedValue({
          data: { ...activeRecord, stalled: true, can_rerun: true },
        });
      wrapper = mountDetail();
      await flushPromises();
      await vi.advanceTimersByTimeAsync(5000);
      expect(DataExportsAPI.show).toHaveBeenCalledTimes(2);
      await vi.advanceTimersByTimeAsync(60_000);
      expect(DataExportsAPI.show).toHaveBeenCalledTimes(2);
      expect(wrapper.text()).toContain('DATA_EXPORTS.RERUN');

      DataExportsAPI.show.mockResolvedValueOnce({ data: activeRecord });
      await wrapper
        .get('[aria-label="DATA_IMPORTS.MONITOR.REFRESH"]')
        .trigger('click');
      await flushPromises();
      expect(DataExportsAPI.show).toHaveBeenCalledTimes(3);
      await vi.advanceTimersByTimeAsync(5000);
      expect(DataExportsAPI.show).toHaveBeenCalledTimes(4);
      await vi.advanceTimersByTimeAsync(5000);
      expect(DataExportsAPI.show).toHaveBeenCalledTimes(4);
    }
  );

  it('shows a persistent error with Retry after an initial failure and recovers on success', async () => {
    DataExportsAPI.show.mockRejectedValueOnce(new Error('Unavailable'));
    wrapper = mountDetail();
    await flushPromises();

    expect(wrapper.get('[role="alert"]').text()).toContain(
      'DATA_EXPORTS.LOAD_ERROR'
    );
    const retry = wrapper.get('[role="alert"] button');
    expect(retry.text()).toBe('DATA_EXPORTS.RETRY');
    let finishRequest;
    DataExportsAPI.show.mockReturnValueOnce(
      new Promise(resolve => {
        finishRequest = resolve;
      })
    );
    await retry.trigger('click');
    expect(retry.attributes('disabled')).toBeDefined();
    expect(DataExportsAPI.show).toHaveBeenCalledTimes(2);

    finishRequest({ data: record });
    await flushPromises();
    expect(wrapper.find('[role="alert"]').exists()).toBe(false);
    expect(wrapper.text()).toContain('Contacts export');
    expect(wrapper.text()).toContain('42');
  });

  it('preserves loaded details after a failed refresh and clears the error on the next poll', async () => {
    DataExportsAPI.show.mockResolvedValueOnce({ data: record });
    wrapper = mountDetail();
    await flushPromises();
    DataExportsAPI.show.mockRejectedValueOnce(new Error('Unavailable'));
    await vi.advanceTimersByTimeAsync(5000);

    expect(wrapper.get('[role="alert"]').text()).toContain(
      'DATA_EXPORTS.LOAD_ERROR'
    );
    expect(wrapper.text()).toContain('Contacts export');
    expect(wrapper.text()).toContain('42');

    DataExportsAPI.show.mockResolvedValueOnce({
      data: { ...record, status: 'completed', processed_records: 100 },
    });
    await vi.advanceTimersByTimeAsync(5000);
    expect(wrapper.find('[role="alert"]').exists()).toBe(false);
    expect(wrapper.text()).toContain('100');
  });
});
