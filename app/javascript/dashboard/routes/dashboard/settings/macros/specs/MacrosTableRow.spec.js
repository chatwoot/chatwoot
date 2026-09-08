import { shallowMount } from '@vue/test-utils';
import MacrosTableRow from '../MacrosTableRow.vue';

const macro = visibility => ({
  id: 1,
  name: 'Close conversation',
  visibility,
  created_by: {
    available_name: 'Maya Chen',
    email: 'maya.chen@example.com',
  },
  updated_by: {
    available_name: 'Maya Chen',
    email: 'maya.chen@example.com',
  },
});

const mountComponent = props =>
  shallowMount(MacrosTableRow, {
    props: {
      macro: macro('global'),
      canManagePublicMacros: true,
      ...props,
    },
    global: {
      stubs: {
        Avatar: true,
        BaseTableRow: {
          template: '<div><slot /></div>',
        },
        BaseTableCell: {
          template: '<div><slot /></div>',
        },
        Button: true,
        RouterLink: {
          template: '<a><slot /></a>',
        },
      },
    },
  });

describe('MacrosTableRow.vue', () => {
  it('shows actions for public macros when public macros can be managed', () => {
    const wrapper = mountComponent();

    expect(wrapper.findAllComponents({ name: 'Button' })).toHaveLength(2);
  });

  it('keeps public macros viewable without delete actions when public macros cannot be managed', () => {
    const wrapper = mountComponent({ canManagePublicMacros: false });

    expect(wrapper.findAllComponents({ name: 'Button' })).toHaveLength(1);
  });

  it('keeps actions available for personal macros when public macros cannot be managed', () => {
    const wrapper = mountComponent({
      macro: macro('personal'),
      canManagePublicMacros: false,
    });

    expect(wrapper.findAllComponents({ name: 'Button' })).toHaveLength(2);
  });
});
