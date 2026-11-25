import { describe, it, expect, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import Facebook from '../Facebook.vue';

// The component drives form submission through @submit.prevent on the <form>.
// Vuelidate/account/branding are irrelevant to that wiring — stub them so the
// form branch renders without a real store or FB SDK.
vi.mock('@vuelidate/core', () => ({
  useVuelidate: () => ({
    selectedPage: { $error: false, $touch: vi.fn() },
    pageName: { $error: false, $touch: vi.fn() },
    $touch: vi.fn(),
    $error: false,
  }),
}));

vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({ accountId: { value: 1 } }),
}));

vi.mock('shared/composables/useBranding', () => ({
  useBranding: () => ({ replaceInstallationName: key => key }),
}));

const mountFacebook = () =>
  mount(Facebook, {
    // user_access_token + !isCreating + !hasError + hasLoginStarted renders the
    // <form> branch (instead of the login splash or the loading state).
    data() {
      return {
        hasLoginStarted: true,
        user_access_token: 'token',
        isCreating: false,
        hasError: false,
        pageList: [{ id: '1', name: 'Page 1', exists: false }],
      };
    },
    global: {
      mocks: { $t: key => key },
      stubs: {
        LoadingState: true,
        PageHeader: true,
        ComboBox: true,
      },
    },
  });

describe('Facebook.vue', () => {
  // Regression: #11237 migrated the create button from <input type="submit"> to
  // NextButton, which defaults to type="button". A plain button never fires the
  // form's @submit.prevent, so clicking "Create Inbox" did nothing.
  it('renders the create-inbox button as a submit so it triggers the form @submit', () => {
    const wrapper = mountFacebook();
    const submitButton = wrapper.find('form button[type="submit"]');
    expect(submitButton.exists()).toBe(true);
  });
});
