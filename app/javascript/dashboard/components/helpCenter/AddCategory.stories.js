import AddCategoryComponent from './AddCategory.vue';
import { action } from '@storybook/addon-actions';

export default {
  title: 'Components/Help Center',
  component: AddCategoryComponent,
  argTypes: {
    show: {
      defaultValue: true,
      control: {
        type: 'boolean',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { AddCategoryComponent },
  template:
    '<add-category-component v-bind="$props" @create="onCreate" @cancel="onClose" />',
});

export const AddCategory = Template.bind({});
AddCategory.args = {
  portalName: 'Chatwoot help center',
  locale: 'En-US',
  onCreate: action('create'),
  onClose: action('cancel'),
};
