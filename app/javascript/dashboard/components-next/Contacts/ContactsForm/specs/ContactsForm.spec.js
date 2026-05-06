import { mount } from '@vue/test-utils';
import ContactsForm from '../ContactsForm.vue';

const componentStubs = {
  Input: { template: '<input />' },
  ComboBox: { template: '<div />' },
  Icon: { template: '<i />' },
  PhoneNumberInput: { template: '<input />' },
};

describe('ContactsForm', () => {
  it('marks the form invalid and blocks update emit when an alias email is invalid', async () => {
    const wrapper = mount(ContactsForm, {
      props: {
        contactData: {
          id: 1,
          name: 'John Doe',
          email: 'primary@example.com',
          emails: ['primary@example.com'],
          additionalAttributes: {
            socialProfiles: {},
          },
        },
      },
      global: {
        mocks: {
          $t: key => key,
        },
        stubs: componentStubs,
      },
    });

    const emailsInput = wrapper.findComponent({ name: 'ContactEmailsInput' });
    await emailsInput.vm.$emit('update:modelValue', [
      'primary@example.com',
      'not-an-email',
    ]);
    await wrapper.vm.$nextTick();

    expect(wrapper.vm.isFormInvalid).toBe(true);
    expect(wrapper.emitted('update')).toBeFalsy();
  });
});
