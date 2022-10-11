import { action } from '@storybook/addon-actions';
import LabelDropdownItem from './LabelDropdownItem';

export default {
  title: 'Components/Label/Item',
  component: LabelDropdownItem,
  argTypes: {
    title: {
      defaultValue: 'sales',
      control: {
        type: 'text',
      },
    },
    color: {
      defaultValue: '#555',
      control: {
        type: 'text',
      },
    },
    selected: {
      defaultValue: true,
      control: {
        type: 'boolean',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { LabelDropdownItem },
  template:
    '<label-dropdown-item v-bind="$props" @click="onClick"></label-dropdown-item>',
});

export const Item = Template.bind({});
Item.args = {
  onClick: action('Selected'),
};
