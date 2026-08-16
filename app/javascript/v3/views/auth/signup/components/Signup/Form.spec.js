import { mount } from '@vue/test-utils';
import Form from './Form.vue';

const { globalConfigState } = vi.hoisted(() => ({
  globalConfigState: { value: {} },
}));

vi.mock('vuex', () => ({
  useStore: () => ({
    getters: {
      'globalConfig/get': globalConfigState.value,
    },
  }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => key,
  }),
}));

vi.mock('vue-router', () => ({
  useRouter: () => ({ push: vi.fn() }),
}));

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

vi.mock('../../../../../api/auth', () => ({
  register: vi.fn(),
}));

vi.mock('@hcaptcha/vue3-hcaptcha', () => ({
  default: { name: 'VueHcaptcha', template: '<div />' },
}));

vi.mock('../../../../../components/GoogleOauth/Button.vue', () => ({
  default: { name: 'GoogleOAuthButton', template: '<div><slot /></div>' },
}));

const mountForm = () =>
  mount(Form, {
    global: {
      stubs: {
        FormInput: {
          props: ['modelValue', 'name', 'hasError'],
          emits: ['update:modelValue'],
          template:
            '<input :name="name" :class="{ error: hasError }" :value="modelValue" @input="$emit(\'update:modelValue\', $event.target.value)" />',
        },
        NextButton: true,
        PasswordRequirements: true,
      },
    },
  });

describe('Signup Form', () => {
  beforeEach(() => {
    window.chatwootConfig = { allowedLoginMethods: ['email'] };
  });

  it('rejects a personal email address when installationName is Chatwoot', async () => {
    globalConfigState.value = { installationName: 'Chatwoot' };
    const wrapper = mountForm();
    const emailInput = wrapper.find('input[name="email_address"]');

    await emailInput.setValue('personal@gmail.com');
    await emailInput.trigger('blur');

    expect(emailInput.classes()).toContain('error');
  });

  it('skips the business email restriction on self-hosted installations', async () => {
    globalConfigState.value = { installationName: 'My Self Hosted Chatwoot' };
    const wrapper = mountForm();
    const emailInput = wrapper.find('input[name="email_address"]');

    await emailInput.setValue('personal@gmail.com');
    await emailInput.trigger('blur');

    expect(emailInput.classes()).not.toContain('error');
  });
});
