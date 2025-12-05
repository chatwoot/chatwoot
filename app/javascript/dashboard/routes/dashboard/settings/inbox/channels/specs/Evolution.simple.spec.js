// Mock vue-router
const mockRouterReplace = vi.fn();
vi.mock('vue-router', () => ({
  useRouter: () => ({
    replace: mockRouterReplace,
  }),
}));

// Mock vue-i18n
vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: msg => msg,
  }),
}));

// Mock the useAlert composable
const mockUseAlert = vi.fn();
vi.mock('dashboard/composables', () => ({
  useAlert: (...args) => mockUseAlert(...args),
}));

// Mock the validators
vi.mock('shared/helpers/Validators', () => ({
  isPhoneE164OrEmpty: value => {
    const phonePattern = /^\+[1-9]\d{1,14}$/;
    return phonePattern.test(value) || value === '';
  },
}));

// Mock NextButton component
vi.mock('dashboard/components-next/button/Button.vue', () => ({
  default: {
    name: 'NextButton',
    template:
      '<button :disabled="isLoading" @click="$emit(\'click\')" data-test-id="submit-button">{{ label }}</button>',
    props: ['isLoading', 'type', 'solid', 'blue', 'label'],
  },
}));

import { shallowMount, flushPromises } from '@vue/test-utils';
import { createStore } from 'vuex';
import Evolution from '../Evolution.vue';

describe('Evolution.vue - Core Logic Tests', () => {
  let wrapper;
  let store;
  let dispatchSpy;

  const createWrapper = (storeConfig = {}) => {
    // Create mock store
    store = createStore({
      modules: {
        inboxes: {
          namespaced: true,
          getters: {
            getUIFlags: () => ({ isCreating: false }),
            ...storeConfig.getters,
          },
          actions: {
            createEvolutionChannel: vi.fn().mockResolvedValue({ id: 123 }),
            ...storeConfig.actions,
          },
        },
      },
    });

    // Spy on store.dispatch
    dispatchSpy = vi.spyOn(store, 'dispatch');

    return shallowMount(Evolution, {
      global: {
        plugins: [store],
        mocks: {
          $t: msg => msg,
        },
        stubs: {
          NextButton: true,
        },
      },
    });
  };

  beforeEach(() => {
    vi.clearAllMocks();
    mockUseAlert.mockClear();
    mockRouterReplace.mockClear();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.unmount();
    }
  });

  describe('Component basics', () => {
    it('renders phone number input field', () => {
      wrapper = createWrapper();

      const phoneInput = wrapper.find('input[type="text"]');
      expect(phoneInput.exists()).toBe(true);
    });

    it('renders submit button', () => {
      wrapper = createWrapper();

      const submitButton = wrapper.findComponent({ name: 'NextButton' });
      expect(submitButton.exists()).toBe(true);
    });
  });

  describe('Phone number validation', () => {
    it('validates E164 format correctly', async () => {
      wrapper = createWrapper();

      // Test valid E164 number - should not have error
      wrapper.vm.phoneNumber = '+5511999999999';
      await wrapper.vm.v$.$validate();
      expect(wrapper.vm.v$.phoneNumber.$error).toBe(false);

      // Test empty is valid for isPhoneE164OrEmpty
      wrapper.vm.phoneNumber = '';
      await wrapper.vm.v$.$validate();
      // Empty fails 'required' but passes 'isPhoneE164OrEmpty'
      expect(wrapper.vm.v$.phoneNumber.isPhoneE164OrEmpty.$invalid).toBe(false);
    });

    it('rejects invalid phone format', async () => {
      wrapper = createWrapper();

      // Test invalid format - missing plus sign
      wrapper.vm.phoneNumber = '5511999999999';
      await wrapper.vm.v$.$validate();
      expect(wrapper.vm.v$.phoneNumber.isPhoneE164OrEmpty.$invalid).toBe(true);
    });

    it('requires phone number', async () => {
      wrapper = createWrapper();

      wrapper.vm.phoneNumber = '';
      await wrapper.vm.v$.$validate();
      expect(wrapper.vm.v$.phoneNumber.required.$invalid).toBe(true);

      wrapper.vm.phoneNumber = '+5511999999999';
      await wrapper.vm.v$.$validate();
      expect(wrapper.vm.v$.phoneNumber.required.$invalid).toBe(false);
    });
  });

  describe('Form submission logic', () => {
    it('strips non-digits from phone number for submission', async () => {
      wrapper = createWrapper();

      // Set valid E164 phone number (validation requires + followed by digits)
      wrapper.vm.phoneNumber = '+5511999999999';

      // Call the createChannel method directly
      await wrapper.vm.createChannel();
      await flushPromises();

      // Verify the name passed is just digits (+ is stripped via /\D/g)
      expect(dispatchSpy).toHaveBeenCalledWith(
        'inboxes/createEvolutionChannel',
        {
          name: '5511999999999',
          channel: {
            type: 'api',
          },
        }
      );
    });

    it('calls router.replace on successful channel creation', async () => {
      wrapper = createWrapper();

      wrapper.vm.phoneNumber = '+5511999999999';

      await wrapper.vm.createChannel();
      await flushPromises();

      expect(mockRouterReplace).toHaveBeenCalledWith({
        name: 'settings_inboxes_add_agents',
        params: {
          page: 'new',
          inbox_id: 123,
        },
      });
    });

    it('shows alert on channel creation error', async () => {
      const errorMessage = 'Failed to create channel';

      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: vi
            .fn()
            .mockRejectedValue(new Error(errorMessage)),
        },
      });

      wrapper.vm.phoneNumber = '+5511999999999';

      await wrapper.vm.createChannel();
      await flushPromises();

      expect(mockUseAlert).toHaveBeenCalledWith(errorMessage);
    });

    it('shows default error message when error has no message', async () => {
      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: vi.fn().mockRejectedValue(new Error()),
        },
      });

      wrapper.vm.phoneNumber = '+5511999999999';

      await wrapper.vm.createChannel();
      await flushPromises();

      expect(mockUseAlert).toHaveBeenCalledWith(
        'INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE'
      );
    });

    it('prevents submission when validation fails', async () => {
      wrapper = createWrapper();

      wrapper.vm.phoneNumber = 'invalid-phone';

      await wrapper.vm.createChannel();
      await flushPromises();

      // Should not dispatch action due to validation failure
      expect(dispatchSpy).not.toHaveBeenCalledWith(
        'inboxes/createEvolutionChannel',
        expect.any(Object)
      );
    });
  });

  describe('Store integration', () => {
    it('gets loading state from store', () => {
      wrapper = createWrapper({
        getters: {
          getUIFlags: () => ({ isCreating: true }),
        },
      });

      expect(wrapper.vm.uiFlags.isCreating).toBe(true);
    });

    it('dispatches createEvolutionChannel action', async () => {
      wrapper = createWrapper();

      wrapper.vm.phoneNumber = '+5511999999999';

      await wrapper.vm.createChannel();
      await flushPromises();

      expect(dispatchSpy).toHaveBeenCalledWith(
        'inboxes/createEvolutionChannel',
        {
          name: '5511999999999',
          channel: {
            type: 'api',
          },
        }
      );
    });
  });

  describe('Evolution-specific behavior', () => {
    it('creates api channel type (Evolution specific)', async () => {
      wrapper = createWrapper();

      wrapper.vm.phoneNumber = '+5511999999999';

      await wrapper.vm.createChannel();
      await flushPromises();

      expect(dispatchSpy).toHaveBeenCalledWith(
        'inboxes/createEvolutionChannel',
        expect.objectContaining({
          channel: {
            type: 'api',
          },
        })
      );
    });

    it('uses phone number without plus sign as name', async () => {
      wrapper = createWrapper();

      // E164 format: + followed by digits
      wrapper.vm.phoneNumber = '+5511999999999';

      await wrapper.vm.createChannel();
      await flushPromises();

      // The + sign is stripped via /\D/g, only digits remain
      expect(dispatchSpy).toHaveBeenCalledWith(
        'inboxes/createEvolutionChannel',
        expect.objectContaining({
          name: '5511999999999',
        })
      );
    });
  });
});
