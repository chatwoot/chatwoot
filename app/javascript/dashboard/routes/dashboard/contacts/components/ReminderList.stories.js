import { action } from '@storybook/addon-actions';
import ReminderList from './ReminderList';

export default {
  title: 'Components/Reminder/List',
  component: ReminderList,
  argTypes: {
    text: {
      defaultValue:
        'A copy and paste musical notes symbols & music symbols collection for easy access.',
      control: {
        type: 'text',
      },
    },
    date: {
      defaultValue: '03/06/2020',
      control: {
        type: 'text',
      },
    },
    label: {
      defaultValue: 'Call',
      control: {
        type: 'text',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ReminderList },
  template:
    '<reminder-list v-bind="$props" @edit="onEdit" @delete="onDelete"></reminder-list>',
});

export const List = Template.bind({});
List.args = {
  onEdit: action('Edit'),
  onDelete: action('Delete'),
};
