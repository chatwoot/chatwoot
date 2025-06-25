import ContactAttribute from '../components/ContactAttribute';
import { action } from '@storybook/addon-actions';

export default {
  title: 'Components/Contact/ContactAttribute',
  component: ContactAttribute,
  argTypes: {
    label: {
      defaultValue: 'Email',
      control: {
        type: 'text',
      },
    },
    value: {
      defaultValue: 'dwight@schrute.farms',
      control: {
        type: 'text',
      },
    },
    icon: {
      defaultValue: 'ion-email',
      control: {
        type: 'text',
      },
    },
    showEdit: {
      control: {
        type: 'boolean',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ContactAttribute },
  template: '<contact-attribute v-bind="$props" @update="onEdit" />',
});

export const DefaultAttribute = Template.bind({});
DefaultAttribute.args = {
  onEdit: action('edit'),
};
