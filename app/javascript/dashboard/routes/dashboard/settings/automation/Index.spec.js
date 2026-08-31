import { ref } from 'vue';
import { flushPromises, shallowMount } from '@vue/test-utils';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import Index from './Index.vue';

vi.mock('vue-i18n');
vi.mock('vue-router');
vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

describe('Automation settings', () => {
  it('opens the automation linked in the URL', async () => {
    const automation = {
      id: 7,
      name: 'Pending follow up',
      execution_delay: 240,
    };
    const openEditDialog = vi.fn();
    let finishLoadingInboxes;
    const inboxesLoaded = new Promise(resolve => {
      finishLoadingInboxes = resolve;
    });
    const store = {
      dispatch: vi.fn(action =>
        action === 'inboxes/get' ? inboxesLoaded : Promise.resolve()
      ),
    };

    useI18n.mockReturnValue({ t: key => key });
    useRoute.mockReturnValue({ query: { automationId: '7' } });
    useStore.mockReturnValue(store);
    useStoreGetters.mockReturnValue({
      'automations/getAutomations': ref([automation]),
      'automations/getUIFlags': ref({ isFetching: false }),
      'accounts/isFeatureEnabledonAccount': ref(() => true),
      getCurrentAccountId: ref(1),
    });

    shallowMount(Index, {
      global: {
        stubs: {
          SettingsLayout: { template: '<div><slot /></div>' },
          EditAutomationRule: {
            props: ['selectedResponse'],
            setup(_, { expose }) {
              expose({ open: openEditDialog, close: vi.fn() });
            },
            template: '<div />',
          },
          'woot-confirm-modal': true,
          'woot-delete-modal': true,
        },
      },
    });
    await flushPromises();

    expect(openEditDialog).not.toHaveBeenCalled();

    finishLoadingInboxes();
    await flushPromises();

    expect(store.dispatch).toHaveBeenCalledWith('automations/get');
    expect(openEditDialog).toHaveBeenCalledWith(automation);
  });
});
