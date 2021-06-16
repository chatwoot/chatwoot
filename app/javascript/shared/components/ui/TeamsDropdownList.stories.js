import { action } from '@storybook/addon-actions';
import TeamsDropdownList from './TeamsDropdownList.vue';

export default {
  title: 'Components/Dropdown/Teams List',
  component: TeamsDropdownList,
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
  components: { TeamsDropdownList },
  template:
    '<teams-dropdown-list v-bind="$props" @click="onClick"></teams-dropdown-list>',
});

export const TeamsList = Template.bind({});
TeamsList.args = {
  onClick: action('Added'),
  options: [
    { id: 0, name: 'None' },
    {
      id: '1',
      name: 'Testing team',
      account_id: 1,
      description: '',
    },
    {
      id: '2',
      name: 'Support team',
      account_id: 1,
      description: '',
    },
  ],
  value: { id: '1' },
};
