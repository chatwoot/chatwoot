import { mount, shallowMount } from '@vue/test-utils';
import AccountOwnerSelect from '../AccountOwnerSelect.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key =>
      ({
        'ACCOUNT_OWNER.LABEL': 'Account Owner',
        'ACCOUNT_OWNER.UNASSIGNED': 'Unassigned',
        'ACCOUNT_OWNER.SEARCH_PLACEHOLDER': 'Search agents',
        'ACCOUNT_OWNER.EMPTY_STATE': 'No agents found',
      })[key] || key,
  }),
}));

describe('AccountOwnerSelect', () => {
  it('renders the exact Account Owner label through the combobox placeholder', () => {
    const wrapper = shallowMount(AccountOwnerSelect, {
      props: {
        agents: [{ id: 7, name: 'Asha Agent', email: 'asha@example.com' }],
        modelValue: '',
      },
      global: {
        stubs: { ComboBox: true },
      },
    });

    expect(
      wrapper.findComponent({ name: 'ComboBox' }).props('placeholder')
    ).toBe('Account Owner');
  });

  it('shows Account Owner in the closed control when no owner is selected', () => {
    const wrapper = mount(AccountOwnerSelect, {
      props: {
        agents: [{ id: 7, name: 'Asha Agent', email: 'asha@example.com' }],
        modelValue: '',
      },
      global: {
        stubs: {
          OnClickOutside: { template: '<div><slot /></div>' },
        },
      },
    });

    expect(wrapper.find('button').text()).toContain('Account Owner');
    expect(wrapper.find('button').text()).not.toContain('Unassigned');
  });

  it('does not include Unassigned as an option when no owner is selected', () => {
    const wrapper = shallowMount(AccountOwnerSelect, {
      props: {
        agents: [{ id: 7, name: 'Asha Agent', email: 'asha@example.com' }],
        modelValue: '',
      },
      global: {
        stubs: { ComboBox: true },
      },
    });

    expect(
      wrapper.findComponent({ name: 'ComboBox' }).props('options')
    ).toEqual([{ label: 'Asha Agent', value: 7 }]);
  });

  it('emits an empty value when Unassigned is selected from an assigned owner', async () => {
    const wrapper = shallowMount(AccountOwnerSelect, {
      props: {
        agents: [{ id: 7, name: 'Asha Agent', email: 'asha@example.com' }],
        modelValue: 7,
      },
      global: {
        stubs: { ComboBox: true },
      },
    });
    const unassignedOption = wrapper
      .findComponent({ name: 'ComboBox' })
      .props('options')
      .find(option => option.label === 'Unassigned');

    await wrapper
      .findComponent({ name: 'ComboBox' })
      .vm.$emit('update:modelValue', unassignedOption.value);

    expect(wrapper.emitted('update:modelValue')[0]).toEqual(['']);
  });

  it('emits selected owner id', async () => {
    const wrapper = shallowMount(AccountOwnerSelect, {
      props: {
        agents: [{ id: 7, name: 'Asha Agent', email: 'asha@example.com' }],
        modelValue: '',
      },
      global: {
        stubs: { ComboBox: true },
      },
    });

    await wrapper
      .findComponent({ name: 'ComboBox' })
      .vm.$emit('update:modelValue', 7);

    expect(wrapper.emitted('update:modelValue')[0]).toEqual([7]);
  });
});
