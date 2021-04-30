import { action } from '@storybook/addon-actions';
import InputField from '../../app/javascript/dashboard/routes/dashboard/contacts/components/Input.vue';

export default {
  title: 'Components/Input Field',
  component: InputField,
  argTypes: {},
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { InputField },
  template: '<input-field v-bind="$props" @add="onAdd"></input-field>',
});

export const Input = Template.bind({});
Input.args = {
  onAdd: action('Added'),
};
