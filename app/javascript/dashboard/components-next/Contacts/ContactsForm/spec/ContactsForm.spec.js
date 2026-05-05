import { defineComponent, h, nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import ContactsForm from '../ContactsForm.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => key,
  }),
}));

const InputStub = defineComponent({
  name: 'MockTextInput',
  inheritAttrs: false,
  props: {
    modelValue: {
      type: String,
      default: '',
    },
  },
  emits: ['update:modelValue', 'input', 'blur'],
  setup(props, { attrs, emit }) {
    return () =>
      h('input', {
        ...attrs,
        value: props.modelValue,
        onBlur: event => emit('blur', event),
        onInput: event => {
          emit('update:modelValue', event.target.value);
          emit('input', event);
        },
      });
  },
});

const buildContactData = () => ({
  id: 42,
  name: 'Bob Example',
  email: 'primary@example.com',
  phoneNumber: '+14155550123',
  emailAddresses: ['primary@example.com', 'old-alias@example.com'],
  additionalAttributes: {
    description: '',
    companyName: '',
    countryCode: '',
    country: '',
    city: '',
    socialProfiles: {
      facebook: '',
      github: '',
      instagram: '',
      telegram: '',
      tiktok: '',
      linkedin: '',
      twitter: '',
    },
  },
});

const buildWrapper = (props = {}) =>
  mount(ContactsForm, {
    props: {
      contactData: buildContactData(),
      ...props,
    },
    global: {
      stubs: {
        Input: InputStub,
        ComboBox: true,
        Icon: true,
        PhoneNumberInput: true,
      },
    },
  });

describe('ContactsForm', () => {
  it('renders alias management in contact details and emits emailAddresses updates', async () => {
    const wrapper = buildWrapper({
      isDetailsView: true,
      showEmailAliases: true,
    });
    await nextTick();

    expect(wrapper.findComponent({ name: 'ContactEmailFields' }).exists()).toBe(
      true
    );

    await wrapper.find('[data-testid="contact-email-add"]').trigger('click');
    await nextTick();

    await wrapper
      .find('[data-testid="contact-email-alias-input-2"]')
      .setValue('billing@example.com');
    await nextTick();

    expect(wrapper.emitted('update').at(-1)[0]).toMatchObject({
      email: 'primary@example.com',
      emailAddresses: [
        'primary@example.com',
        'old-alias@example.com',
        'billing@example.com',
      ],
    });

    await wrapper
      .find('[data-testid="contact-email-primary-2"]')
      .trigger('click');
    await nextTick();

    expect(wrapper.emitted('update').at(-1)[0]).toMatchObject({
      email: 'billing@example.com',
      emailAddresses: [
        'billing@example.com',
        'primary@example.com',
        'old-alias@example.com',
      ],
    });

    await wrapper
      .find('[data-testid="contact-email-remove-2"]')
      .trigger('click');
    await nextTick();

    expect(wrapper.emitted('update').at(-1)[0]).toMatchObject({
      email: 'billing@example.com',
      emailAddresses: ['billing@example.com', 'primary@example.com'],
    });
  });

  it('keeps new-contact mode in single-email mode', () => {
    const wrapper = buildWrapper({
      contactData: null,
      isNewContact: true,
    });

    expect(wrapper.findComponent({ name: 'ContactEmailFields' }).exists()).toBe(
      false
    );
  });
});
