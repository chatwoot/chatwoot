import { flushPromises, mount } from '@vue/test-utils';
import { createMemoryHistory, createRouter } from 'vue-router';
import DataImportsAPI from 'dashboard/api/dataImports';
import DataExportsAPI from 'dashboard/api/dataExports';
import dataRoutes from '../data.routes';
import NewImportDialog from '../NewImportDialog.vue';
import NewExportDialog from '../NewExportDialog.vue';
import ExportsList from '../ExportsList.vue';
import { saveExportDraft } from '../exportDraft';

vi.mock('dashboard/api/dataImports', () => ({ default: { get: vi.fn() } }));
vi.mock('dashboard/api/dataExports', () => ({ default: { get: vi.fn() } }));
vi.mock('dashboard/composables/store', () => ({
  useStoreGetters: () => ({ getCurrentAccountId: { value: 1 } }),
}));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('../../components/BaseSettingsHeader.vue', () => ({
  default: { template: '<header />' },
}));

describe('data operation navigation', () => {
  let router;
  let wrapper;

  beforeEach(() => {
    sessionStorage.clear();
    DataImportsAPI.get.mockResolvedValue({
      data: { payload: [], can_create_import: true },
    });
    DataExportsAPI.get.mockResolvedValue({ data: { payload: [] } });
    router = createRouter({
      history: createMemoryHistory(),
      routes: dataRoutes.routes,
    });
  });

  afterEach(() => {
    wrapper?.unmount();
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
            SettingsLayout: { template: '<main><slot name="body" /></main>' },
            Button: true,
            Icon: true,
            NewImportDialog: true,
            NewExportDialog: true,
            ExportsList: true,
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

  it('follows tab changes in browser navigation without reloading history', async () => {
    await openPage({ tab: 'import' });
    await router.push({ query: { tab: 'export' } });
    await flushPromises();
    expect(wrapper.findComponent(ExportsList).exists()).toBe(true);

    router.back();
    await flushPromises();
    expect(wrapper.findComponent(ExportsList).exists()).toBe(false);
    expect(DataImportsAPI.get).toHaveBeenCalledTimes(1);
  });
});
