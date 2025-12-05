// Mock the useAlert composable
vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
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

import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import Evolution from '../Evolution.vue';

describe('Evolution.vue - Core Logic Tests', () => {
  let wrapper;
  let store;

  const createWrapper = (storeConfig = {}) => {
    // Create mock store
    store = createStore({
      modules: {
        inboxes: {
          namespaced: true,
          getters: {
            getUIFlags: () => ({ isCreating: false }),
          },
          actions: {
            createEvolutionChannel: vi.fn(),
          },
          ...storeConfig,
        },
      },
    });

    return shallowMount(Evolution, {
      global: {
        plugins: [store],
        mocks: {
          $t: msg => msg,
          $router: {
            replace: vi.fn(),
          },
        },
        stubs: {
          NextButton: true,
        },
      },
    });
  };

  beforeEach(() => {
    vi.clearAllMocks();
    useAlert.mockClear?.();
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
    it('validates E164 format correctly', () => {
      wrapper = createWrapper();

      // Test valid E164 numbers
      expect(
        wrapper.vm.v$.phoneNumber.isPhoneE164OrEmpty.$validator(
          '+5511999999999'
        )
      ).toBe(true);
      expect(
        wrapper.vm.v$.phoneNumber.isPhoneE164OrEmpty.$validator('+1234567890')
      ).toBe(true);
      expect(wrapper.vm.v$.phoneNumber.isPhoneE164OrEmpty.$validator('')).toBe(
        true
      );

      // Test invalid formats
      expect(
        wrapper.vm.v$.phoneNumber.isPhoneE164OrEmpty.$validator('5511999999999')
      ).toBe(false);
      expect(
        wrapper.vm.v$.phoneNumber.isPhoneE164OrEmpty.$validator('invalid')
      ).toBe(false);
    });

    it('requires phone number', () => {
      wrapper = createWrapper();

      expect(wrapper.vm.v$.phoneNumber.required.$validator('')).toBe(false);
      expect(
        wrapper.vm.v$.phoneNumber.required.$validator('+5511999999999')
      ).toBe(true);
    });
  });

  describe('Form submission logic', () => {
    it('strips non-digits from phone number for submission', async () => {
      const createEvolutionChannelMock = vi.fn().mockResolvedValue({ id: 123 });
      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: createEvolutionChannelMock,
        },
      });

      // Set phone number with special characters
      wrapper.vm.phoneNumber = '+55 (11) 99999-9999';

      // Call the createChannel method directly
      await wrapper.vm.createChannel();

      expect(createEvolutionChannelMock).toHaveBeenCalledWith(
        expect.any(Object),
        {
          name: '5511999999999',
          channel: {
            type: 'api',
          },
        }
      );
    });

    it('calls router.replace on successful channel creation', async () => {
      const createEvolutionChannelMock = vi.fn().mockResolvedValue({ id: 123 });
      const routerReplaceMock = vi.fn();

      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: createEvolutionChannelMock,
        },
      });

      wrapper.vm.$router.replace = routerReplaceMock;
      wrapper.vm.phoneNumber = '+5511999999999';

      await wrapper.vm.createChannel();

      expect(routerReplaceMock).toHaveBeenCalledWith({
        name: 'settings_inboxes_add_agents',
        params: {
          page: 'new',
          inbox_id: 123,
        },
      });
    });

    it('shows alert on channel creation error', async () => {
      const errorMessage = 'Failed to create channel';
      const createEvolutionChannelMock = vi
        .fn()
        .mockRejectedValue(new Error(errorMessage));

      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: createEvolutionChannelMock,
        },
      });

      wrapper.vm.phoneNumber = '+5511999999999';

      await wrapper.vm.createChannel();

      expect(useAlert).toHaveBeenCalledWith(errorMessage);
    });

    it('shows default error message when error has no message', async () => {
      const createEvolutionChannelMock = vi.fn().mockRejectedValue(new Error());

      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: createEvolutionChannelMock,
        },
      });

      wrapper.vm.phoneNumber = '+5511999999999';

      await wrapper.vm.createChannel();

      expect(useAlert).toHaveBeenCalledWith(
        'INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE'
      );
    });

    it('prevents submission when validation fails', async () => {
      const createEvolutionChannelMock = vi.fn();

      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: createEvolutionChannelMock,
        },
      });

      wrapper.vm.phoneNumber = 'invalid-phone';
      wrapper.vm.v$.$touch(); // Trigger validation

      await wrapper.vm.createChannel();

      expect(createEvolutionChannelMock).not.toHaveBeenCalled();
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
      const createEvolutionChannelMock = vi.fn().mockResolvedValue({ id: 123 });

      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: createEvolutionChannelMock,
        },
      });

      wrapper.vm.phoneNumber = '+5511999999999';

      await wrapper.vm.createChannel();

      expect(createEvolutionChannelMock).toHaveBeenCalledWith(
        expect.any(Object),
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
      const createEvolutionChannelMock = vi.fn().mockResolvedValue({ id: 123 });

      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: createEvolutionChannelMock,
        },
      });

      wrapper.vm.phoneNumber = '+5511999999999';

      await wrapper.vm.createChannel();

      expect(createEvolutionChannelMock).toHaveBeenCalledWith(
        expect.any(Object),
        expect.objectContaining({
          channel: {
            type: 'api',
          },
        })
      );
    });

    it('uses phone number without formatting as name', async () => {
      const createEvolutionChannelMock = vi.fn().mockResolvedValue({ id: 123 });

      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: createEvolutionChannelMock,
        },
      });

      wrapper.vm.phoneNumber = '+55 (11) 99999-9999';

      await wrapper.vm.createChannel();

      expect(createEvolutionChannelMock).toHaveBeenCalledWith(
        expect.any(Object),
        expect.objectContaining({
          name: '5511999999999', // Stripped of all non-digits
        })
      );
    });
  });
});
