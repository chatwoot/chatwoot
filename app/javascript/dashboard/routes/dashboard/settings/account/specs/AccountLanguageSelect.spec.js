import { flushPromises, mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import AccountSettings from '../Index.vue';

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({ accountId: 1 }),
}));
vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: () => ({ uiSettings: {}, updateUISettings: vi.fn() }),
}));

const enabledLanguages = [
  { name: '日本語 (ja)', iso_639_1_code: 'ja' },
  { name: 'Português Brasileiro (pt-BR)', iso_639_1_code: 'pt_BR' },
  { name: 'English (en)', iso_639_1_code: 'en' },
  { name: 'Português (pt)', iso_639_1_code: 'pt' },
];

describe('Account settings language selection', () => {
  it('searches the existing sorted catalogue and changes the raw locale only on form submission', async () => {
    window.chatwootConfig = { enabledLanguages };
    const update = vi.fn();
    const store = createStore({
      modules: {
        accounts: {
          namespaced: true,
          state: { account: { id: 1, name: 'Team', locale: 'en' } },
          getters: {
            getAccount:
              ({ account }) =>
              () =>
                account,
            getUIFlags: () => ({}),
            isFeatureEnabledonAccount: () => () => false,
          },
          actions: { update },
        },
        globalConfig: {
          namespaced: true,
          getters: { isOnChatwootCloud: () => false },
        },
      },
    });
    const wrapper = mount(AccountSettings, {
      attachTo: document.body,
      global: {
        plugins: [store],
        stubs: {
          BaseSettingsHeader: true,
          AccountId: true,
          BuildInfo: true,
          NextButton: false,
          WootLoadingState: true,
          FluentIcon: true,
        },
      },
    });

    try {
      await flushPromises();
      const trigger = wrapper.get('#site-language');
      expect(trigger.text()).toBe('English (en)');
      expect(trigger.attributes('type')).toBe('button');
      await trigger.trigger('click');
      expect(
        wrapper.findAll('[role="option"]').map(node => node.text())
      ).toEqual([
        'English (en)',
        '日本語 (ja)',
        'Português (pt)',
        'Português Brasileiro (pt-BR)',
      ]);

      const input = wrapper.get('input[type="search"]');
      await input.setValue('Brazilian Portuguese');
      expect(
        wrapper.findAll('[role="option"]').map(node => node.text())
      ).toEqual(['Português Brasileiro (pt-BR)']);
      await input.trigger('keydown', { key: 'Enter' });
      expect(trigger.text()).toBe('Português Brasileiro (pt-BR)');
      expect(update).not.toHaveBeenCalled();

      await wrapper.get('form').trigger('submit');
      await flushPromises();
      expect(update).toHaveBeenCalledTimes(1);
      expect(update.mock.calls[0][1]).toMatchObject({ locale: 'pt_BR' });
      expect(store.getters['accounts/getAccount']().locale).toBe('pt_BR');
    } finally {
      wrapper.unmount();
      delete window.chatwootConfig;
    }
  });
});
