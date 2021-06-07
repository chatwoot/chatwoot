import { action } from '@storybook/addon-actions';
import ReminderItem from './ReminderItem';

export default {
  title: 'Components/Reminder/Item',
  component: ReminderItem,
  argTypes: {
    id: {
      control: {
        type: 'number',
      },
    },
    text: {
      defaultValue:
        'A copy and paste musical notes symbols & music symbols collection for easy access.',
      control: {
        type: 'text',
      },
    },
    isCompleted: {
      control: {
        type: 'boolean',
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
  components: { ReminderItem },
  template:
    '<reminder-item v-bind="$props" @completed="onClick" @edit="onEdit" @delete="onDelete"></reminder-item>',
});

export const Item = Template.bind({});
Item.args = {
  onClick: action('Marked'),
  onEdit: action('Edit'),
  onDelete: action('Delete'),
};
