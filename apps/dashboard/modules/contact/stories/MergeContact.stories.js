import { action } from '@storybook/addon-actions';
import MergeContact from 'dashboard/modules/contact/components/MergeContact';

export default {
  title: 'Components/Contact/MergeContacts',
  component: MergeContact,
  argTypes: {
    'primary-contact': {
      defaultValue: '{}',
      control: {
        type: 'object',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { MergeContact },
  template:
    '<merge-contact v-bind="$props" @submit="onSearch" @search="onSubmit"></merge-contact>',
});

export const List = Template.bind({});
List.args = {
  primaryContact: {
    id: 12,
    name: 'Mason Mount',
  },
  onSearch: action('Search'),
  onSubmit: action('Submit'),
};
