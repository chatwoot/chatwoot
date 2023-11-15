import { action } from '@storybook/addon-actions';
import AddReminder from './AddReminder';

export default {
  title: 'Components/Reminder/Add',
  component: AddReminder,
  argTypes: {
    options: {
      control: {
        type: 'object',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { AddReminder },
  template:
    '<add-reminder v-bind="$props" @add="onAdd" @click="onClick"></add-reminder>',
});

export const Add = Template.bind({});
Add.args = {
  onAdd: action('Added'),
  onClick: action('Label'),
  options: [
    {
      id: '12345',
      name: 'calls',
    },
    {
      id: '12346',
      name: 'meeting',
    },
    {
      id: '12347',
      name: 'review',
    },
  ],
};
