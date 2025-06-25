import { action } from '@storybook/addon-actions';
import AddLabel from './AddLabel';

export default {
  title: 'Components/Label/Add Button',
  component: AddLabel,
  argTypes: {},
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { AddLabel },
  template: '<add-label v-bind="$props" @add="onClick"></add-label>',
});

export const AddButton = Template.bind({});
AddButton.args = {
  onClick: action('opened'),
};
