import { action } from '@storybook/addon-actions';
import LabelDropdown from './LabelDropdown';

export default {
  title: 'Components/Label/Dropdown',
  component: LabelDropdown,
  argTypes: {
    conversationId: {
      control: {
        type: 'text',
      },
    },
    accountLabels: {
      defaultValue: [
        {
          color: '#555',
          description: '',
          id: 1,
          title: 'sales',
        },
        {
          color: '#c242f5',
          description: '',
          id: 1,
          title: 'business',
        },
        {
          color: '#4287f5',
          description: '',
          id: 1,
          title: 'testing',
        },
      ],
      control: {
        type: 'object',
      },
    },
    selectedLabels: {
      defaultValue: 'sales, testing',
      control: {
        type: 'object',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { LabelDropdown },
  template:
    '<label-dropdown v-bind="$props" @add="onAdd" @remove="onRemove"></label-dropdown>',
});

export const Dropdown = Template.bind({});
Dropdown.args = {
  onAdd: action('added'),
  onRemove: action('removed'),
};
