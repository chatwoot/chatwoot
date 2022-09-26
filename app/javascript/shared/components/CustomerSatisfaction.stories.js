import { action } from '@storybook/addon-actions';
import CustomerSatisfaction from './CustomerSatisfaction';

export default {
  title: 'Components/CustomerSatisfaction',
  component: CustomerSatisfaction,
  argTypes: {},
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { CustomerSatisfaction },
  template: '<customer-satisfaction />',
});

export const Item = Template.bind({});
Item.args = {
  onClick: action('Selected'),
};
