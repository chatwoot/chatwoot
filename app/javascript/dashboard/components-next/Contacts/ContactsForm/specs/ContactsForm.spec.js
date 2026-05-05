import { shallowMount } from '@vue/test-utils';
import ContactsForm from '../ContactsForm.vue';

const tMock = vi.fn(
  key => ({ 'ACCOUNT_OWNER.LABEL': 'Account Owner' })[key] || key
);

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: tMock,
  }),
}));

describe('ContactsForm', () => {
  beforeEach(() => {
    tMock.mockClear();
  });

  it('passes account owner options and emits accountOwnerId', async () => {
    const wrapper = shallowMount(ContactsForm, {
      props: {
        contactData: {
          id: 1,
          name: 'Ada Lovelace',
          email: 'ada@example.com',
          phoneNumber: '',
          accountOwnerId: 7,
          additionalAttributes: {},
        },
        agents: [{ id: 7, name: 'Asha Agent', email: 'asha@example.com' }],
      },
      global: {
        stubs: {
          Input: true,
          ComboBox: true,
          Icon: true,
          PhoneNumberInput: true,
          AccountOwnerSelect: true,
        },
      },
    });

    const ownerSelect = wrapper.findComponent({ name: 'AccountOwnerSelect' });
    expect(ownerSelect.exists()).toBe(true);
    expect(ownerSelect.props('modelValue')).toBe(7);

    await ownerSelect.vm.$emit('update:modelValue', 8);

    expect(wrapper.emitted('update').at(-1)[0]).toMatchObject({
      accountOwnerId: 8,
    });
  });

  it('keeps the picker model empty and emits null when owner is cleared', async () => {
    const wrapper = shallowMount(ContactsForm, {
      props: {
        contactData: {
          id: 1,
          name: 'Ada Lovelace',
          email: 'ada@example.com',
          phoneNumber: '',
          accountOwnerId: 7,
          additionalAttributes: {},
        },
        agents: [{ id: 7, name: 'Asha Agent', email: 'asha@example.com' }],
      },
      global: {
        stubs: {
          Input: true,
          ComboBox: true,
          Icon: true,
          PhoneNumberInput: true,
          AccountOwnerSelect: true,
        },
      },
    });

    const ownerSelect = wrapper.findComponent({ name: 'AccountOwnerSelect' });

    await ownerSelect.vm.$emit('update:modelValue', '');

    expect(wrapper.emitted('update').at(-1)[0]).toMatchObject({
      accountOwnerId: null,
    });
    expect(ownerSelect.props('modelValue')).toBe('');
  });

  it('uses the shared account owner label instead of a nested contact placeholder', () => {
    shallowMount(ContactsForm, {
      props: {
        contactData: {
          id: 1,
          name: 'Ada Lovelace',
          email: 'ada@example.com',
          phoneNumber: '',
          additionalAttributes: {},
        },
      },
      global: {
        stubs: {
          Input: true,
          ComboBox: true,
          Icon: true,
          PhoneNumberInput: true,
          AccountOwnerSelect: true,
        },
      },
    });

    expect(tMock).toHaveBeenCalledWith('ACCOUNT_OWNER.LABEL');
    expect(tMock).not.toHaveBeenCalledWith(
      'CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.FORM.ACCOUNT_OWNER.PLACEHOLDER'
    );
  });

  it('does not render account owner picker for a new contact', () => {
    const wrapper = shallowMount(ContactsForm, {
      props: {
        isNewContact: true,
        contactData: {
          id: 1,
          name: 'Ada Lovelace',
          email: 'ada@example.com',
          phoneNumber: '',
          additionalAttributes: {},
        },
      },
      global: {
        stubs: {
          Input: true,
          ComboBox: true,
          Icon: true,
          PhoneNumberInput: true,
          AccountOwnerSelect: true,
        },
      },
    });

    expect(wrapper.findComponent({ name: 'AccountOwnerSelect' }).exists()).toBe(
      false
    );
  });
});
