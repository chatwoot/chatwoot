import { action } from '@storybook/addon-actions';
import AddReminder from './AddReminder';

export default {
  title: 'Components/Reminder/Add',
  component: AddReminder,
  argTypes: {
    types: {
      defaultValue: 'call',
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
};
