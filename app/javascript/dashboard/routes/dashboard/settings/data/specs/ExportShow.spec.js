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
    const wrapper = mount(
      {
        components: { KeepAlive, ExportShow },
        template: '<KeepAlive><ExportShow /></KeepAlive>',
      },
      {
        global: {
          stubs: {
            SettingsLayout: { template: '<main><slot name="header"/></main>' },
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
