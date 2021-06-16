import { action } from '@storybook/addon-actions';
import AgentDropdownSelector from './AgentDropdown';

export default {
  title: 'Components/Dropdown/Agents Dropdown',
  component: AgentDropdownSelector,
  argTypes: {
    agentsList: {
      control: {
        type: 'object',
      },
    },
    assignedAgent: {
      control: {
        type: 'object',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { AgentDropdownSelector },
  template:
    '<agent-dropdown-selector v-bind="$props" @click="onClick"></agent-dropdown-selector>',
});

export const AgentsDropdown = Template.bind({});
AgentsDropdown.args = {
  onClick: action('Opened'),
  agentsList: [
    {
      account_id: 1,
      availability_status: 'online',
      available_name: 'John',
      email: 'john@gmail.com',
      id: 1,
      name: 'John',
      role: 'administrator',
      thumbnail: 'https://randomuser.me/api/portraits/men/4.jpg',
    },
  ],

  assignedAgent: {
    account_id: 1,
    availability_status: 'online',
    available_name: 'John',
    email: 'john@gmail.com',
    id: 1,
    name: 'John',
    role: 'administrator',
    thumbnail: 'https://randomuser.me/api/portraits/men/4.jpg',
  },
};
