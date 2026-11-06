import { flushPromises, mount } from '@vue/test-utils';
import { createMemoryHistory, createRouter } from 'vue-router';
import DataImportsAPI from 'dashboard/api/dataImports';
import { useAlert } from 'dashboard/composables';
import dataRoutes from '../data.routes';
import NewImportDialog from '../NewImportDialog.vue';

vi.mock('dashboard/api/dataImports', () => ({ default: { get: vi.fn() } }));
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
      data: { payload: [], can_create_import: true },
    });
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
