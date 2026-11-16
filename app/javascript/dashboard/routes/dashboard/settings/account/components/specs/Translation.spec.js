import { nextTick, ref } from 'vue';
import { mount } from '@vue/test-utils';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter, useFunctionGetter } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import Translation from '../Translation.vue';

vi.mock('dashboard/composables/useAccount');
vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables/useTranslationPlan', () => ({
  useTranslationPlan: () => ({ needsUpgrade: ref(false) }),
}));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('vuex', () => ({ useStore: () => ({ dispatch: vi.fn() }) }));
vi.mock('vue-router', () => ({ useRouter: () => ({ push: vi.fn() }) }));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));

const OTHER_PROVIDERS = 'GENERAL_SETTINGS.FORM.TRANSLATION.OTHER_PROVIDERS';
const SWITCH_BUTTON = 'GENERAL_SETTINGS.FORM.TRANSLATION.GOOGLE.SWITCH_BUTTON';

const updateAccount = vi.fn();

const mountTranslation = ({
  provider,
  captainEnabled = true,
  googleConnected = true,
  currentAccount = ref({ id: 1, settings: { translation_provider: provider } }),
}) => {
  useAccount.mockReturnValue({
    accountId: ref(1),
    currentAccount,
    updateAccount,
  });
  useMapGetter.mockReturnValue(
    ref(
      (_accountId, flag) =>
        flag === FEATURE_FLAGS.CAPTAIN_TASKS &&
        captainEnabled &&
        !!currentAccount.value.id
    )
  );
  useFunctionGetter.mockReturnValue(ref({ enabled: googleConnected }));

  return mount(Translation, {
    global: {
      stubs: { NextButton: false, RouterLink: { template: '<a><slot /></a>' } },
    },
  });
};

const findButton = (wrapper, label) =>
  wrapper.findAll('button').find(button => button.text().includes(label));

describe('Translation', () => {
  beforeEach(() => {
    updateAccount.mockReset();
  });

  it('keeps Google Translate behind the disclosure when Captain is saved', async () => {
    const wrapper = mountTranslation({ provider: 'captain' });

    expect(wrapper.find('#google_translate').exists()).toBe(false);

    await findButton(wrapper, OTHER_PROVIDERS).trigger('click');

    expect(wrapper.find('#google_translate').exists()).toBe(true);
  });

  it('stays collapsed when the account loads after mount with Captain saved', async () => {
    const currentAccount = ref({});
    const wrapper = mountTranslation({ currentAccount });

    currentAccount.value = {
      id: 1,
      settings: { translation_provider: 'captain' },
    };
    await nextTick();

    expect(wrapper.find('#google_translate').exists()).toBe(false);
  });

  it('collapses other providers after switching from Google back to Captain', async () => {
    const currentAccount = ref({
      id: 1,
      settings: { translation_provider: 'captain' },
    });
    const wrapper = mountTranslation({ currentAccount });

    await findButton(wrapper, OTHER_PROVIDERS).trigger('click');
    currentAccount.value = {
      id: 1,
      settings: { translation_provider: 'google_translate' },
    };
    await nextTick();
    currentAccount.value = {
      id: 1,
      settings: { translation_provider: 'captain' },
    };
    await nextTick();

    expect(wrapper.find('#google_translate').exists()).toBe(false);
  });

  it('opens with Google selected and switches back to Captain', async () => {
    const wrapper = mountTranslation({ provider: 'google_translate' });

    expect(wrapper.find('#google_translate').element.checked).toBe(true);
    expect(findButton(wrapper, OTHER_PROVIDERS).exists()).toBe(true);

    await findButton(wrapper, SWITCH_BUTTON).trigger('click');

    expect(updateAccount).toHaveBeenCalledWith(
      { translation_provider: 'captain' },
      { silent: true }
    );
  });

  it('shows Google without the disclosure when Captain is not enabled', () => {
    const wrapper = mountTranslation({
      provider: 'google_translate',
      captainEnabled: false,
    });

    expect(wrapper.find('#google_translate').exists()).toBe(true);
    expect(findButton(wrapper, OTHER_PROVIDERS)).toBeUndefined();
    expect(findButton(wrapper, SWITCH_BUTTON)).toBeUndefined();
  });
});
