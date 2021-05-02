import { action } from '@storybook/addon-actions';
import AddNote from './AddNote.vue';

export default {
  title: 'Components/Notes/Add',
  component: AddNote,
  argTypes: {},
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { AddNote },
  template: '<add-note v-bind="$props" @add="onAdd"></add-note>',
});

export const Add = Template.bind({});
Add.args = {
  onAdd: action('Added'),
};
