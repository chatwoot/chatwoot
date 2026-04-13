import { mount } from '@vue/test-utils';
import ContactForm from '../ContactForm.vue';

const globalStubs = {
  NextButton: { template: '<button />' },
  Avatar: { template: '<div />' },
  ComboBox: { template: '<div />' },
  ContactEmailsInput: {
    name: 'ContactEmailsInput',
    template: '<div />',
  },
  'woot-phone-input': { template: '<input />' },
  'woot-input': { template: '<input />' },
};

describe('Conversation ContactForm', () => {
  it('blocks submit when any alias email is invalid', async () => {
    const onSubmit = vi.fn();
    const wrapper = mount(ContactForm, {
      props: {
        contact: {
          id: 1,
          name: 'John Doe',
          email: 'primary@example.com',
          emails: ['primary@example.com'],
          additional_attributes: {},
        },
        onSubmit,
      },
      global: {
        mocks: {
          $t: key => key,
          $store: {
            dispatch: vi.fn(),
          },
        },
        stubs: globalStubs,
      },
    });

    wrapper.vm.handleEmailsUpdate(['primary@example.com', 'not-an-email']);
    await wrapper.vm.handleSubmit();

    expect(onSubmit).not.toHaveBeenCalled();
  });
});
