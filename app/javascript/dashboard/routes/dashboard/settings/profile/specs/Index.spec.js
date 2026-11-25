import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { clearCookiesOnLogout } from 'dashboard/store/utils/api.js';
import ProfileSettings from '../Index.vue';

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: () => ({
    isEditorHotKeyEnabled: vi.fn(),
    updateUISettings: vi.fn(),
  }),
}));
vi.mock('dashboard/composables/useFontSize', () => ({
  useFontSize: () => ({ currentFontSize: 'default', updateFontSize: vi.fn() }),
}));
vi.mock('dashboard/composables/useInboxSignatures', () => ({
  useInboxSignatures: () => ({
    upsertInboxSignature: vi.fn(),
    deleteInboxSignature: vi.fn(),
    fetchInboxSignatures: vi.fn(),
  }),
}));
vi.mock('shared/composables/useBranding', () => ({
  useBranding: () => ({ replaceInstallationName: text => text }),
}));
vi.mock('dashboard/store/utils/api.js', async importOriginal => ({
  ...(await importOriginal()),
  clearCookiesOnLogout: vi.fn(),
}));

// The profile the server answers with. With Devise's reconfirmable on, a new email waits
// in unconfirmed_email until the link mailed to it is clicked, so the answer still holds
// the current address; with it off, the answer already holds the new one.
const mountWith = serverEmail => {
  const store = createStore({
    state: {
      currentUser: {
        id: 1,
        name: 'John',
        email: 'a@example.com',
        accounts: [],
      },
    },
    getters: {
      getCurrentUser: state => state.currentUser,
      getCurrentUserID: state => state.currentUser.id,
      'globalConfig/get': () => ({}),
      'globalConfig/isOnChatwootCloud': () => false,
    },
    mutations: {
      setCurrentUser(state, user) {
        state.currentUser = user;
      },
    },
    actions: {
      updateProfile({ commit, state }, payload) {
        commit('setCurrentUser', {
          ...state.currentUser,
          name: payload.name,
          email: serverEmail,
        });
      },
    },
  });

  return shallowMount(ProfileSettings, {
    global: {
      plugins: [store],
      mocks: {
        $t: (key, params) =>
          params ? `${key} ${JSON.stringify(params)}` : key,
      },
    },
  });
};

describe('profile settings: changing the email', () => {
  beforeEach(() => vi.clearAllMocks());

  it('keeps the session and says a confirmation link was sent when the change is pending', async () => {
    const wrapper = mountWith('a@example.com');

    await wrapper.vm.updateProfile({ name: 'John', email: 'b@example.com' });

    expect(clearCookiesOnLogout).not.toHaveBeenCalled();
    expect(useAlert).toHaveBeenCalledWith(
      'PROFILE_SETTINGS.EMAIL_CONFIRMATION_PENDING {"email":"b@example.com"}'
    );
    expect(wrapper.vm.email).toBe('a@example.com');
  });

  it('signs out as before when the change takes effect at once', async () => {
    const wrapper = mountWith('b@example.com');

    await wrapper.vm.updateProfile({ name: 'John', email: 'b@example.com' });

    expect(clearCookiesOnLogout).toHaveBeenCalledOnce();
    expect(useAlert).toHaveBeenCalledWith(
      'PROFILE_SETTINGS.AFTER_EMAIL_CHANGED'
    );
  });

  it('does neither when the email did not change', async () => {
    const wrapper = mountWith('a@example.com');

    await wrapper.vm.updateProfile({ name: 'Johnny', email: 'a@example.com' });

    expect(clearCookiesOnLogout).not.toHaveBeenCalled();
    expect(useAlert).toHaveBeenCalledWith('PROFILE_SETTINGS.UPDATE_SUCCESS');
  });

  // Devise stores the email downcased and stripped, so this saves nothing new and no
  // confirmation link goes out.
  it('treats a change of case alone as no change', async () => {
    const wrapper = mountWith('a@example.com');

    await wrapper.vm.updateProfile({ name: 'John', email: ' A@Example.com ' });

    expect(clearCookiesOnLogout).not.toHaveBeenCalled();
    expect(useAlert).toHaveBeenCalledWith('PROFILE_SETTINGS.UPDATE_SUCCESS');
    expect(wrapper.vm.email).toBe('a@example.com');
  });

  // The first answer puts the field back on the current address while the second save
  // is still in flight; that save must not read the field to decide.
  it('keeps the session when the same change is saved twice before the first answer', async () => {
    const wrapper = mountWith('a@example.com');

    await Promise.all([
      wrapper.vm.updateProfile({ name: 'John', email: 'b@example.com' }),
      wrapper.vm.updateProfile({ name: 'John', email: 'b@example.com' }),
    ]);

    expect(clearCookiesOnLogout).not.toHaveBeenCalled();
    expect(useAlert).not.toHaveBeenCalledWith(
      'PROFILE_SETTINGS.AFTER_EMAIL_CHANGED'
    );
  });
});
