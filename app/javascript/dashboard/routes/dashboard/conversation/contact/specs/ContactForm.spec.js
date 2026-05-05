import { shallowMount } from '@vue/test-utils';
import ContactForm from '../ContactForm.vue';

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

const baseAdditionalAttributes = {
  description: '',
  company_name: '',
  country_code: 'US',
  country: 'United States',
  city: 'Portland',
  social_profiles: {},
};

const buildContact = (overrides = {}) => ({
  id: 7,
  name: 'Bob Example',
  email: 'primary@example.com',
  additional_emails: ['alias@example.com'],
  email_addresses: [
    'primary@example.com',
    'alias@example.com',
    'other@example.com',
  ],
  phone_number: '+14155550123',
  additional_phones: ['+14155550124'],
  phone_numbers: ['+14155550123', '+14155550124', '+14155550125'],
  thumbnail: '',
  additional_attributes: baseAdditionalAttributes,
  ...overrides,
});

const buildWrapper = (contact = buildContact(), props = {}) =>
  shallowMount(ContactForm, {
    props: {
      contact,
      ...props,
    },
    global: {
      mocks: {
        $t: key => key,
        $store: {
          dispatch: vi.fn(),
        },
      },
      stubs: {
        Avatar: true,
        ComboBox: true,
        NextButton: true,
        'woot-input': true,
        'woot-phone-input': true,
      },
    },
  });

describe('conversation ContactForm', () => {
  it('uses additional contact point arrays ahead of legacy full lists', () => {
    const wrapper = buildWrapper();

    expect(wrapper.vm.additionalEmails).toEqual(['alias@example.com']);
    expect(wrapper.vm.additionalPhones).toEqual(['+14155550124']);
  });

  it('falls back to full contact point lists after removing the primary value', () => {
    const wrapper = buildWrapper(
      buildContact({
        additional_emails: [],
        email_addresses: [
          'first@example.com',
          'primary@example.com',
          'alias@example.com',
          'first@example.com',
        ],
        additional_phones: [],
        phone_numbers: ['+14155550125', '+14155550123', '+14155550125'],
      })
    );

    expect(wrapper.vm.additionalEmails).toEqual([
      'first@example.com',
      'alias@example.com',
    ]);
    expect(wrapper.vm.additionalPhones).toEqual(['+14155550125']);
  });

  it('includes additional contact points in the submit payload', () => {
    const wrapper = buildWrapper();

    wrapper.vm.additionalEmails = ['alias@example.com', 'billing@example.com'];
    wrapper.vm.additionalPhones = ['+14155550124', '+14155550125'];

    expect(wrapper.vm.getContactObject()).toMatchObject({
      id: 7,
      email: 'primary@example.com',
      phone_number: '+14155550123',
      additional_emails: ['alias@example.com', 'billing@example.com'],
      additional_phones: ['+14155550124', '+14155550125'],
    });
  });
});
