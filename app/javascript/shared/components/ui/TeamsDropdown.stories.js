import { action } from '@storybook/addon-actions';
import TeamsDropdownSelector from './TeamsDropdown.vue';

export default {
  title: 'Components/Dropdown/Teams Dropdown',
  component: TeamsDropdownSelector,
  argTypes: {
    teamsList: {
      control: {
        type: 'object',
      },
    },
    assignedTeam: {
      control: {
        type: 'object',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { TeamsDropdownSelector },
  template:
    '<teams-dropdown-selector v-bind="$props" @click="onClick"></teams-dropdown-selector>',
});

export const TeamsDropdown = Template.bind({});
TeamsDropdown.args = {
  onClick: action('Opened'),
  teamsList: [
    {
      id: '1',
      name: 'Testing team',
      account_id: 1,
      description: '',
    },
  ],

  assignedTeam: {
    id: '1',
    name: 'Testing team',
    account_id: 1,
    description: '',
  },
};
