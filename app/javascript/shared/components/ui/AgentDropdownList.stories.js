import { action } from '@storybook/addon-actions';
import AgentDropdownList from './AgentDropdownList';

export default {
  title: 'Components/Dropdown/Agents List',
  component: AgentDropdownList,
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
  components: { AgentDropdownList },
  template:
    '<agent-dropdown-list v-bind="$props" @click="onClick"></agent-dropdown-list>',
});

export const AgentsList = Template.bind({});
AgentsList.args = {
  onClick: action('Added'),
  options: [
    {
      id: '0',
      name: 'None',
      thumbnail: '',
    },
    {
      id: '1',
      name: 'John',
      availability_status: 'online',
      role: 'administrator',
      thumbnail: 'https://randomuser.me/api/portraits/men/4.jpg',
    },
    {
      id: '2',
      name: 'James Philip',
      availability_status: 'busy',
      role: 'agent',
      thumbnail: 'https://randomuser.me/api/portraits/men/17.jpg',
    },
  ],

  value: { id: '1' },
};
