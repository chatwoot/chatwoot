import { action } from '@storybook/addon-actions';
import DropdownWithSearch from './DropdownWithSearch';

export default {
  title: 'Components/Dropdown/Agent',
  component: DropdownWithSearch,
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
  components: { DropdownWithSearch },
  template:
    '<dropdown-with-search v-bind="$props" @add="onClick"></dropdown-with-search>',
});

export const Agent = Template.bind({});
Agent.args = {
  onClick: action('opened'),
  options: [
    {
      id: '1',
      name: 'John',
      thumbnail: '',
      availability_status: 'online',
    },
    {
      id: '2',
      name: 'Tim Donarld',
      thumbnail: '',
      availability_status: 'offline',
    },
    {
      id: '3',
      name: 'James Philip',
      thumbnail: '',
      availability_status: 'busy',
    },
  ],
  value: { id: '2' },
};
