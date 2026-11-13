import { flushPromises, shallowMount } from '@vue/test-utils';
import { useCommandBar } from '@chatwoot/jumpbar';
import { createMemoryHistory, createRouter } from 'vue-router';
import { createStore } from 'vuex';
import { usePolicy } from 'dashboard/composables/usePolicy';
import ContactsHeader from '../ContactHeader.vue';
import ContactListHeaderWrapper from '../ContactListHeaderWrapper.vue';

vi.mock('dashboard/composables/usePolicy');

describe('Contacts import shortcuts', () => {
  const bar = useCommandBar();
  let router;
  let wrapper;
  let store;

  beforeEach(async () => {
    usePolicy.mockReturnValue({ checkPermissions: () => true });
    store = createStore({
      getters: {
        getCurrentAccountId: () => 42,
        'contacts/getAppliedContactFiltersV4': () => [],
        'attributes/getContactAttributes': () => [],
        'labels/getLabels': () => [],
      },
    });
    vi.spyOn(store, 'dispatch');
    router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: '/', component: { template: '<div />' } },
        {
          path: '/app/accounts/:accountId/settings/data',
          name: 'settings_data_imports',
          component: { template: '<div />' },
        },
      ],
    });
    await router.push('/');
    await router.isReady();
  });

  afterEach(() => {
    wrapper?.unmount();
    bar.dispose();
  });

  const mountHeader = () => {
    wrapper = shallowMount(ContactListHeaderWrapper, {
      global: { plugins: [router, store] },
    });
  };

  it.each(['header', 'command bar'])(
    'opens the Settings CSV import flow from the %s without starting an import',
    async source => {
      mountHeader();
      if (source === 'header') {
        wrapper.getComponent(ContactsHeader).vm.$emit('import');
      } else {
        bar.open();
        await flushPromises();
        const command = bar.visible.value.find(
          item => item.id === 'import_contacts'
        );
        expect(command).toBeDefined();
        await command.run();
      }
      await flushPromises();

      expect(router.currentRoute.value).toMatchObject({
        name: 'settings_data_imports',
        params: { accountId: '42' },
        query: { tab: 'import', action: 'import', source: 'csv' },
      });
      expect(store.dispatch).not.toHaveBeenCalled();
    }
  );

  it('does not offer the import command without contact-management permission', async () => {
    usePolicy.mockReturnValue({ checkPermissions: () => false });
    mountHeader();
    bar.open();
    await flushPromises();

    expect(bar.visible.value.map(item => item.id)).not.toContain(
      'import_contacts'
    );
    expect(router.currentRoute.value.path).toBe('/');
  });
});
