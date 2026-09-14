import { shallowMount } from '@vue/test-utils';
import { ref } from 'vue';
import ImapSmtpOption from '../ImapSmtpOption.vue';
import Input from 'dashboard/components-next/input/Input.vue';

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('vue-router', () => ({ useRouter: () => ({ push: vi.fn() }) }));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: vi.fn() }),
  useMapGetter: () => ref({}),
}));

describe('ImapSmtpOption', () => {
  it('keeps the default login in sync while typing but preserves a custom login', async () => {
    const wrapper = shallowMount(ImapSmtpOption);
    const inputs = wrapper.findAllComponents(Input);
    const email = inputs.find(input =>
      input.props('label').endsWith('EMAIL.LABEL')
    );
    const login = inputs.find(input =>
      input.props('label').endsWith('IMAP.LOGIN.LABEL')
    );

    await email.setValue('s');
    await email.setValue('support@example.com');
    expect(login.props('modelValue')).toBe('support@example.com');

    await login.setValue('custom-login');
    await email.setValue('help@example.com');
    expect(login.props('modelValue')).toBe('custom-login');
  });
});
