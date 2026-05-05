import { defineComponent, h, nextTick } from 'vue';
import { flushPromises, mount } from '@vue/test-utils';
import ContactsForm from '../ContactsForm.vue';
import ContactPointListInput from '../ContactPointListInput.vue';

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
  emailAddresses: ['legacy-primary@example.com', 'legacy-alias@example.com'],
  additionalEmails: ['old-alias@example.com'],
  phoneNumbers: ['+14155550999', '+14155550888'],
  additionalPhones: ['+14155550124'],
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
  it('maps API contact point fields to camelCase state and serializable payloads', async () => {
    const wrapper = buildWrapper({
      isDetailsView: true,
      showContactPoints: true,
    });
    await nextTick();

    expect(wrapper.vm.state).toMatchObject({
      email: 'primary@example.com',
      additionalEmails: ['old-alias@example.com'],
      phoneNumber: '+14155550123',
      additionalPhones: ['+14155550124'],
    });
    expect(wrapper.vm.getSerializableState()).toMatchObject({
      email: 'primary@example.com',
      additionalEmails: ['old-alias@example.com'],
      phoneNumber: '+14155550123',
      additionalPhones: ['+14155550124'],
    });
  });

  it('falls back to snake_case and full address arrays from API payloads', async () => {
    const wrapper = buildWrapper({
      contactData: {
        ...buildContactData(),
        additionalEmails: undefined,
        additional_emails: ['snake-alias@example.com'],
        additionalPhones: undefined,
        additional_phones: ['+14155550125'],
      },
      isDetailsView: true,
      showContactPoints: true,
    });
    await nextTick();

    expect(wrapper.vm.state.additionalEmails).toEqual([
      'snake-alias@example.com',
    ]);
    expect(wrapper.vm.state.additionalPhones).toEqual(['+14155550125']);

    await wrapper.setProps({
      contactData: {
        ...buildContactData(),
        id: 43,
        additionalEmails: undefined,
        additional_emails: undefined,
        emailAddresses: undefined,
        email_addresses: ['api-primary@example.com', 'api-alias@example.com'],
        additionalPhones: undefined,
        additional_phones: undefined,
        phoneNumbers: undefined,
        phone_numbers: ['+14155550126', '+14155550127'],
      },
    });
    await nextTick();

    expect(wrapper.vm.state.email).toBe('primary@example.com');
    expect(wrapper.vm.state.additionalEmails).toEqual([
      'api-alias@example.com',
    ]);
    expect(wrapper.vm.state.phoneNumber).toBe('+14155550123');
    expect(wrapper.vm.state.additionalPhones).toEqual(['+14155550127']);
  });

  it('renders contact point management and emits promoted email and phone payloads', async () => {
    const wrapper = buildWrapper({
      isDetailsView: true,
      showContactPoints: true,
    });
    await nextTick();

    const [emailListComponent, phoneListComponent] = wrapper.findAllComponents(
      ContactPointListInput
    );

    emailListComponent.vm.$emit('update:modelValue', [
      'old-alias@example.com',
      '',
    ]);
    await nextTick();
    await flushPromises();

    emailListComponent.vm.$emit('update:modelValue', [
      'old-alias@example.com',
      'billing@example.com',
    ]);
    await nextTick();
    await flushPromises();

    expect(wrapper.emitted('update').at(-1)[0]).toMatchObject({
      email: 'primary@example.com',
      additionalEmails: ['old-alias@example.com', 'billing@example.com'],
      phoneNumber: '+14155550123',
      additionalPhones: ['+14155550124'],
    });

    emailListComponent.vm.$emit('promote', 'billing@example.com');
    await nextTick();
    await flushPromises();

    expect(wrapper.emitted('update').at(-1)[0]).toMatchObject({
      email: 'billing@example.com',
      additionalEmails: ['primary@example.com', 'old-alias@example.com'],
    });

    phoneListComponent.vm.$emit('promote', '+14155550124');
    await nextTick();
    await flushPromises();

    expect(wrapper.emitted('update').at(-1)[0]).toMatchObject({
      phoneNumber: '+14155550124',
      additionalPhones: ['+14155550123'],
    });

    emailListComponent.vm.$emit('update:modelValue', ['primary@example.com']);
    await nextTick();
    await flushPromises();

    expect(wrapper.emitted('update').at(-1)[0]).toMatchObject({
      email: 'billing@example.com',
      additionalEmails: ['primary@example.com'],
    });
  });

  it('keeps new-contact mode in single-email mode', () => {
    const wrapper = buildWrapper({
      contactData: null,
      isNewContact: true,
    });

    expect(wrapper.find('[data-testid="contact-email-list"]').exists()).toBe(
      false
    );
    expect(wrapper.find('[data-testid="contact-phone-list"]').exists()).toBe(
      false
    );
  });
});
