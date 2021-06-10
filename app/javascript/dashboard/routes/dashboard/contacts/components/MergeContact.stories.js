import { action } from '@storybook/addon-actions';
import MergeContact from './MergeContact';

export default {
  title: 'Components/Contact/MergeContacts',
  component: MergeContact,
  argTypes: {},
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { MergeContact },
  template: '<merge-contact v-bind="$props"></merge-contact>',
});

export const List = Template.bind({});
List.args = {};
