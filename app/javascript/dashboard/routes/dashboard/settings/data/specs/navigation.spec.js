import { flushPromises, mount } from '@vue/test-utils';
import { createMemoryHistory, createRouter } from 'vue-router';
import DataImportsAPI from 'dashboard/api/dataImports';
import { useAlert } from 'dashboard/composables';
import DataExportsAPI from 'dashboard/api/dataExports';
import dataRoutes from '../data.routes';
import NewImportDialog from '../NewImportDialog.vue';
import NewExportDialog from '../NewExportDialog.vue';
import DataOperationList from '../components/DataOperationList.vue';
import { saveExportDraft } from '../exportDraft';

vi.mock('dashboard/api/dataImports', () => ({ default: { get: vi.fn() } }));
vi.mock('dashboard/api/dataExports', () => ({ default: { get: vi.fn() } }));
vi.mock('dashboard/composables/store', () => ({
  useStoreGetters: () => ({ getCurrentAccountId: { value: 1 } }),
}));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('../../components/BaseSettingsHeader.vue', () => ({
  default: { template: '<header><slot name="actions" /></header>' },
}));

describe('data operation navigation', () => {
  let router;
  let wrapper;

  beforeEach(() => {
    vi.useFakeTimers();
    sessionStorage.clear();
    DataImportsAPI.get.mockResolvedValue({
      data: { payload: [{ id: 1 }], can_create_import: true },
    });
    DataExportsAPI.get.mockResolvedValue({ data: { payload: [{ id: 2 }] } });
    router = createRouter({
      history: createMemoryHistory(),
      routes: dataRoutes.routes,
    });
  });

  afterEach(() => {
    wrapper?.unmount();
    vi.useRealTimers();
    vi.clearAllMocks();
    sessionStorage.clear();
  });

  const openPage = async query => {
    await router.push({
      name: 'settings_data_imports',
      params: { accountId: 1 },
      query,
    });
    await router.isReady();
    wrapper = mount(
      { template: '<router-view />' },
      {
        global: {
          plugins: [router],
          stubs: {
            SettingsLayout: {
              template:
                '<main><slot name="header" /><slot name="body" /></main>',
            },
            Button: {
              props: ['label', 'disabled'],
              template: '<button :disabled="disabled">{{ label }}</button>',
            },
            Icon: true,
            NewImportDialog: true,
            NewExportDialog: true,
            DataOperationList: true,
          },
          mocks: { $t: key => key },
        },
      }
    );
    await flushPromises();
  };

  it('keeps the import dialog open after consuming a Contacts shortcut', async () => {
    await openPage({ tab: 'import', action: 'import' });

    expect(router.currentRoute.value.query).toEqual({ tab: 'import' });
    expect(wrapper.findComponent(NewImportDialog).props('show')).toBe(true);
    expect(DataImportsAPI.get).toHaveBeenCalledTimes(1);
  });

  it('keeps the selected export scope after consuming its draft', async () => {
    const draft = saveExportDraft(1, { label: 'vip', scope_name: 'VIP' });
    await openPage({ tab: 'export', action: 'export', draft });

    expect(router.currentRoute.value.query).toEqual({ tab: 'export' });
    expect(wrapper.findComponent(NewExportDialog).props()).toMatchObject({
      show: true,
      selection: { label: 'vip', scope_name: 'VIP' },
    });
    expect(DataImportsAPI.get).toHaveBeenCalledTimes(1);
  });

  it('keeps older rows when a new export arrives during a load-more request', async () => {
    vi.useFakeTimers();
    const page = (ids, hasMore) => ({
      data: {
        payload: ids.map(id => ({ id, status: 'processing' })),
        has_more: hasMore,
      },
    });
    let finishOlder;
    DataExportsAPI.get
      .mockResolvedValueOnce(page([10, 9], true))
      .mockImplementationOnce(
        () =>
          new Promise(resolve => {
            finishOlder = resolve;
          })
      )
      .mockResolvedValueOnce(page([11, 10], true));
    try {
      await openPage({ tab: 'export' });
      const findLoadOlder = () =>
        wrapper
          .findAll('button')
          .find(button => button.text() === 'DATA_EXPORTS.LOAD_OLDER');
      await findLoadOlder().trigger('click');
      expect(DataExportsAPI.get).toHaveBeenNthCalledWith(2, { beforeId: 9 });

      await vi.advanceTimersByTimeAsync(5000);
      expect(DataExportsAPI.get).toHaveBeenNthCalledWith(3);
      finishOlder(page([8, 7], false));
      await flushPromises();
      const rows = wrapper.getComponent(DataOperationList).props('items');
      expect(rows.map(row => row.id)).toEqual([11, 10, 9, 8, 7]);
      expect(findLoadOlder()).toBeUndefined();
    } finally {
      vi.useRealTimers();
    }
  });

  it('follows tab changes in browser navigation without reloading history', async () => {
    await openPage({ tab: 'import' });
    await router.push({ query: { tab: 'export' } });
    await flushPromises();
    expect(wrapper.getComponent(DataOperationList).props('type')).toBe(
      'export'
    );

    router.back();
    await flushPromises();
    expect(wrapper.getComponent(DataOperationList).props('type')).toBe(
      'import'
    );
    expect(DataImportsAPI.get).toHaveBeenCalledTimes(1);
  });

  it('explains an account-wide import block and recovers when the hidden import finishes', async () => {
    DataImportsAPI.get.mockResolvedValueOnce({
      data: { payload: [], can_create_import: false },
    });
    await openPage({ tab: 'import' });

    const buttons = wrapper
      .findAll('button')
      .filter(button => button.text() === 'DATA_IMPORTS.TABLE.NEW_IMPORT');
    expect(buttons).toHaveLength(2);
    expect(buttons.every(button => !button.element.disabled)).toBe(true);
    await buttons[0].trigger('click');
    await buttons[1].trigger('click');
    expect(useAlert).toHaveBeenCalledTimes(2);
    expect(useAlert).toHaveBeenCalledWith('DATA_IMPORTS.DRAWER.ACTIVE_IMPORT');
    expect(wrapper.getComponent(NewImportDialog).props('show')).toBe(false);

    await vi.advanceTimersByTimeAsync(5000);
    expect(DataImportsAPI.get).toHaveBeenCalledTimes(2);
    await buttons[0].trigger('click');
    expect(wrapper.getComponent(NewImportDialog).props('show')).toBe(true);
    expect(wrapper.getComponent(NewImportDialog).props('hasActiveImport')).toBe(
      false
    );
    await vi.advanceTimersByTimeAsync(5000);
    expect(DataImportsAPI.get).toHaveBeenCalledTimes(2);
  });

  it('explains the active import when entering from the Contacts shortcut', async () => {
    DataImportsAPI.get.mockResolvedValue({
      data: { payload: [], can_create_import: false },
    });
    await openPage({ tab: 'import', action: 'import' });

    expect(useAlert).toHaveBeenCalledWith('DATA_IMPORTS.DRAWER.ACTIVE_IMPORT');
    expect(wrapper.getComponent(NewImportDialog).props('show')).toBe(false);
    expect(router.currentRoute.value.query).toEqual({ tab: 'import' });
  });

  it('keeps creation unavailable when the initial history request fails', async () => {
    DataImportsAPI.get.mockRejectedValue(new Error('Network error'));
    await openPage({ tab: 'import' });

    const buttons = wrapper
      .findAll('button')
      .filter(button => button.text() === 'DATA_IMPORTS.TABLE.NEW_IMPORT');
    expect(buttons.every(button => button.element.disabled)).toBe(true);
    expect(wrapper.get('[role="alert"]').text()).toBe(
      'DATA_IMPORTS.ALERTS.LOAD_FAILED'
    );
    expect(useAlert).not.toHaveBeenCalled();
    await vi.advanceTimersByTimeAsync(5000);
    expect(DataImportsAPI.get).toHaveBeenCalledTimes(1);
  });
});
