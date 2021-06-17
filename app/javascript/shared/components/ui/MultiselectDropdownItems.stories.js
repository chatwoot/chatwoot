import { action } from '@storybook/addon-actions';
import DropdownItems from './MultiselectDropdownItems';

export default {
  title: 'Components/Dropdown/Multiselect Dropdown Items',
  component: DropdownItems,
  argTypes: {
    options: {
      control: {
        type: 'object',
      },
    },
    value: {
      control: {
        type: 'object',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { DropdownItems },
  template:
    '<dropdown-items v-bind="$props" @click="onClick"></dropdown-items>',
});

export const MultiselectDropdownItems = Template.bind({});
MultiselectDropdownItems.args = {
  onClick: action('Added'),
  options: [
    {
      id: '0',
      name: 'None',
      thumbnail: '',
    },
    {
      id: '1',
      name: 'James Philip',
      availability_status: 'online',
      role: 'administrator',
      thumbnail: 'https://randomuser.me/api/portraits/men/4.jpg',
    },
    {
      id: '2',
      name: 'Support Team',
      thumbnail: '',
    },
    {
      id: '3',
      name: 'Agent',
      thumbnail: '',
    },
  ],

  value: { id: '1' },
};
