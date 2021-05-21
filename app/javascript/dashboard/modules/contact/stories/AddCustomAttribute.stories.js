import AddCustomAttribute from '../components/AddCustomAttribute';
import { action } from '@storybook/addon-actions';

export default {
  title: 'Components/Contact/AddCustomAttribute',
  component: AddCustomAttribute,
  argTypes: {
    show: {
      defaultValue: true,
      control: {
        type: 'boolean',
      },
    },
    isCreating: {
      defaultValue: false,
      control: {
        type: 'boolean',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { AddCustomAttribute },
  template: '<add-custom-attribute v-bind="$props" @create="onCreate" />',
});

export const DefaultAttribute = Template.bind({});
DefaultAttribute.args = {
  onCreate: action('edit'),
};
