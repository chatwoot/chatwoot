// Mock the useAlert composable
vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

import { mount, flushPromises } from '@vue/test-utils';
import { createStore } from 'vuex';
import { createI18n } from 'vue-i18n';
import { createRouter, createWebHistory } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import Evolution from '../Evolution.vue';

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
      '<button :disabled="isLoading" @click="$emit(\'click\')" data-test-id="submit-button"><slot /></button>',
    props: ['isLoading', 'type', 'solid', 'blue', 'label'],
  },
}));

describe('Evolution.vue', () => {
  let wrapper;
  let store;
  let router;
  let i18n;

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

    // Create mock router
    router = createRouter({
      history: createWebHistory(),
      routes: [
        { path: '/', component: { template: '<div>Home</div>' } },
        {
          path: '/settings/inboxes/add_agents/:page/:inbox_id',
          name: 'settings_inboxes_add_agents',
          component: { template: '<div>Add Agents</div>' },
        },
      ],
    });

    // Create i18n instance - legacy: false required for Composition API useI18n()
    i18n = createI18n({
      legacy: false,
      locale: 'en',
      messages: {
        en: {
          INBOX_MGMT: {
            ADD: {
              WHATSAPP: {
                PHONE_NUMBER: {
                  LABEL: 'Phone Number',
                  PLACEHOLDER: '+1 234 567 8901',
                  ERROR: 'Please enter a valid phone number in E164 format',
                },
                SUBMIT_BUTTON: 'Create Evolution Channel',
                API: {
                  ERROR_MESSAGE: 'Failed to create Evolution channel',
                },
              },
            },
          },
        },
      },
    });

    return mount(Evolution, {
      global: {
        plugins: [store, router, i18n],
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

  describe('Component rendering', () => {
    it('renders phone number input field', () => {
      wrapper = createWrapper();

      const phoneInput = wrapper.find('input[type="text"]');
      expect(phoneInput.exists()).toBe(true);
      expect(phoneInput.attributes('placeholder')).toBe('+1 234 567 8901');
    });

    it('renders submit button', () => {
      wrapper = createWrapper();

      // NextButton is stubbed, find the stub component
      const submitButton = wrapper.findComponent({ name: 'NextButton' });
      expect(submitButton.exists()).toBe(true);
    });

    it('displays phone number label', () => {
      wrapper = createWrapper();

      const label = wrapper.find('label');
      expect(label.text()).toContain('Phone Number');
    });
  });

  describe('Form validation', () => {
    it('validates phone number on blur', async () => {
      wrapper = createWrapper();

      const phoneInput = wrapper.find('input[type="text"]');
      await phoneInput.setValue('invalid-phone');
      await phoneInput.trigger('blur');
      await flushPromises();

      const errorMessage = wrapper.find('.message');
      expect(errorMessage.exists()).toBe(true);
      expect(errorMessage.text()).toBe(
        'Please enter a valid phone number in E164 format'
      );
    });

    it('accepts valid E164 phone number', async () => {
      wrapper = createWrapper();

      const phoneInput = wrapper.find('input[type="text"]');
      await phoneInput.setValue('+5511999999999');
      await phoneInput.trigger('blur');
      await flushPromises();

      const errorMessage = wrapper.find('.message');
      expect(errorMessage.exists()).toBe(false);
    });

    it('shows error for empty phone number (required field)', async () => {
      wrapper = createWrapper();

      const phoneInput = wrapper.find('input[type="text"]');
      await phoneInput.setValue('');
      await phoneInput.trigger('blur');
      await flushPromises();

      // Empty phone number fails 'required' validation
      const errorMessage = wrapper.find('.message');
      expect(errorMessage.exists()).toBe(true);
    });

    it('rejects phone number without plus sign', async () => {
      wrapper = createWrapper();

      const phoneInput = wrapper.find('input[type="text"]');
      await phoneInput.setValue('5511999999999');
      await phoneInput.trigger('blur');
      await flushPromises();

      const errorMessage = wrapper.find('.message');
      expect(errorMessage.exists()).toBe(true);
    });

    it('applies error class to label when validation fails', async () => {
      wrapper = createWrapper();

      const phoneInput = wrapper.find('input[type="text"]');
      await phoneInput.setValue('invalid');
      await phoneInput.trigger('blur');
      await flushPromises();

      const label = wrapper.find('label');
      expect(label.classes()).toContain('error');
    });
  });

  describe('Form submission', () => {
    it('prevents submission with invalid phone number', async () => {
      const createEvolutionChannelMock = vi.fn();
      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: createEvolutionChannelMock,
        },
      });

      const phoneInput = wrapper.find('input[type="text"]');
      await phoneInput.setValue('invalid-phone');

      const form = wrapper.find('form');
      await form.trigger('submit.prevent');
      await flushPromises();

      expect(createEvolutionChannelMock).not.toHaveBeenCalled();
    });

    it('submits form with valid phone number', async () => {
      const createEvolutionChannelMock = vi.fn().mockResolvedValue({ id: 123 });
      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: createEvolutionChannelMock,
        },
      });

      const phoneInput = wrapper.find('input[type="text"]');
      await phoneInput.setValue('+5511999999999');

      const form = wrapper.find('form');
      await form.trigger('submit.prevent');
      await flushPromises();

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

    it('strips plus sign from phone number in submission', async () => {
      const createEvolutionChannelMock = vi.fn().mockResolvedValue({ id: 123 });
      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: createEvolutionChannelMock,
        },
      });

      const phoneInput = wrapper.find('input[type="text"]');
      // Use valid E164 format (validation requires + followed by digits only)
      await phoneInput.setValue('+5511999999999');

      const form = wrapper.find('form');
      await form.trigger('submit.prevent');
      await flushPromises();

      // The name is stripped of non-digits via /\D/g (removes the +)
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

    it('navigates to agent assignment on successful submission', async () => {
      const createEvolutionChannelMock = vi.fn().mockResolvedValue({ id: 123 });
      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: createEvolutionChannelMock,
        },
      });

      const phoneInput = wrapper.find('input[type="text"]');
      await phoneInput.setValue('+5511999999999');

      const routerSpy = vi.spyOn(wrapper.vm.$router, 'replace');

      const form = wrapper.find('form');
      await form.trigger('submit.prevent');
      await flushPromises();

      expect(routerSpy).toHaveBeenCalledWith({
        name: 'settings_inboxes_add_agents',
        params: {
          page: 'new',
          inbox_id: 123,
        },
      });
    });

    it('shows alert on submission error', async () => {
      const errorMessage = 'Failed to create channel';
      const createEvolutionChannelMock = vi
        .fn()
        .mockRejectedValue(new Error(errorMessage));
      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: createEvolutionChannelMock,
        },
      });

      const phoneInput = wrapper.find('input[type="text"]');
      await phoneInput.setValue('+5511999999999');

      const form = wrapper.find('form');
      await form.trigger('submit.prevent');
      await flushPromises();

      expect(useAlert).toHaveBeenCalledWith(errorMessage);
    });

    it('shows default error message when error has no message', async () => {
      const createEvolutionChannelMock = vi.fn().mockRejectedValue(new Error());
      wrapper = createWrapper({
        actions: {
          createEvolutionChannel: createEvolutionChannelMock,
        },
      });

      const phoneInput = wrapper.find('input[type="text"]');
      await phoneInput.setValue('+5511999999999');

      const form = wrapper.find('form');
      await form.trigger('submit.prevent');
      await flushPromises();

      expect(useAlert).toHaveBeenCalledWith(
        'Failed to create Evolution channel'
      );
    });
  });

  describe('Loading state', () => {
    it('displays loading state from store', () => {
      wrapper = createWrapper({
        getters: {
          getUIFlags: () => ({ isCreating: true }),
        },
      });

      const submitButton = wrapper.findComponent({ name: 'NextButton' });
      expect(submitButton.props('isLoading')).toBe(true);
    });

    it('does not display loading state when not creating', () => {
      wrapper = createWrapper({
        getters: {
          getUIFlags: () => ({ isCreating: false }),
        },
      });

      const submitButton = wrapper.findComponent({ name: 'NextButton' });
      expect(submitButton.props('isLoading')).toBe(false);
    });
  });

  describe('User interaction', () => {
    it('trims whitespace from phone number input', async () => {
      wrapper = createWrapper();

      const phoneInput = wrapper.find('input[type="text"]');
      await phoneInput.setValue('  +5511999999999  ');

      expect(wrapper.vm.phoneNumber).toBe('+5511999999999');
    });

    it('updates phone number reactively', async () => {
      wrapper = createWrapper();

      const phoneInput = wrapper.find('input[type="text"]');
      await phoneInput.setValue('+5511999999999');

      expect(wrapper.vm.phoneNumber).toBe('+5511999999999');
    });
  });

  describe('Component integration', () => {
    it('integrates correctly with Vuex store', () => {
      wrapper = createWrapper();

      expect(wrapper.vm.$store.getters['inboxes/getUIFlags']).toBeDefined();
    });

    it('integrates correctly with Vue Router', () => {
      wrapper = createWrapper();

      expect(wrapper.vm.$router).toBeDefined();
      expect(wrapper.vm.$router.replace).toBeDefined();
    });

    it('integrates correctly with i18n', () => {
      wrapper = createWrapper();

      expect(wrapper.vm.$t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.LABEL')).toBe(
        'Phone Number'
      );
    });
  });
});
