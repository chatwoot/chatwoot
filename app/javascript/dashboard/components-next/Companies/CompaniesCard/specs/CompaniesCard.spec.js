import { shallowMount } from '@vue/test-utils';
import CompaniesCard from '../CompaniesCard.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, values) => {
      if (key === 'COMPANIES.CONTACTS_COUNT') {
        return `${values.n} contacts`;
      }

      return (
        {
          'ACCOUNT_OWNER.LABEL': 'Account Owner',
          'COMPANIES.UNNAMED': 'Unnamed Company',
        }[key] || key
      );
    },
  }),
}));

const AccountOwnerSelectStub = {
  name: 'AccountOwnerSelect',
  props: {
    modelValue: { type: [Number, String], default: '' },
    agents: { type: Array, default: () => [] },
    disabled: { type: Boolean, default: false },
  },
  emits: ['update:modelValue'],
  template:
    '<button data-testid="owner-select" @click="$emit(\'update:modelValue\', \'\')">{{ modelValue }}</button>',
};

const CardLayoutStub = {
  name: 'CardLayout',
  emits: ['click'],
  template:
    '<div data-testid="company-card" @click="$emit(\'click\', $event)"><slot /></div>',
};

const mountCard = props =>
  shallowMount(CompaniesCard, {
    props: {
      id: 12,
      name: 'Acme',
      ...props,
    },
    global: {
      stubs: {
        AccountOwnerSelect: AccountOwnerSelectStub,
        Avatar: true,
        CardLayout: CardLayoutStub,
        Icon: true,
      },
    },
  });

describe('CompaniesCard', () => {
  it('passes account owner state to the shared owner picker', () => {
    const agents = [{ id: 7, name: 'Asha Agent' }];
    const wrapper = mountCard({
      accountOwnerId: 7,
      agents,
      isUpdating: true,
    });

    const ownerSelect = wrapper.findComponent({ name: 'AccountOwnerSelect' });

    expect(ownerSelect.props('modelValue')).toBe(7);
    expect(ownerSelect.props('agents')).toEqual(agents);
    expect(ownerSelect.props('disabled')).toBe(true);
  });

  it('emits null when the owner is cleared', async () => {
    const wrapper = mountCard({ accountOwnerId: 7 });
    const ownerSelect = wrapper.findComponent({ name: 'AccountOwnerSelect' });

    await ownerSelect.vm.$emit('update:modelValue', '');

    expect(wrapper.emitted('updateOwner')[0]).toEqual([
      {
        id: 12,
        accountOwnerId: null,
      },
    ]);
  });

  it('keeps owner picker clicks from opening company details', async () => {
    const wrapper = mountCard({ accountOwnerId: 7 });

    await wrapper.find('[data-testid="owner-select"]').trigger('click');

    expect(wrapper.emitted('showCompany')).toBeUndefined();
  });

  it('remounts the owner picker when the reset key changes', async () => {
    const wrapper = mountCard({
      accountOwnerId: 7,
      ownerPickerResetKey: 0,
    });
    const firstOwnerSelectUid = wrapper.findComponent({
      name: 'AccountOwnerSelect',
    }).vm.$.uid;

    await wrapper.setProps({ ownerPickerResetKey: 1 });

    expect(
      wrapper.findComponent({ name: 'AccountOwnerSelect' }).vm.$.uid
    ).not.toBe(firstOwnerSelectUid);
  });
});
