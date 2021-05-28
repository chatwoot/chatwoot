import { action } from '@storybook/addon-actions';
import ContactLabel from './ContactLabel';

export default {
  title: 'Components/Labels/Contact',
  component: ContactLabel,
  argTypes: {
    conversationId: {
      control: {
        type: 'text ,number',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ContactLabel },
  template:
    '<contact-label v-bind="$props" @add="onAdd" @remove="onRemove"></contact-label>',
});

export const Contact = Template.bind({});
Contact.args = {
  onAdd: action('Added'),
  onRemove: action('Removed'),
  allLabels: [
    {
      id: '1',
      title: 'sales',
      description: '',
      color: '#0a5dd1',
    },
    {
      id: '2',
      title: 'refund',
      description: '',
      color: '#8442f5',
    },
    {
      id: '3',
      title: 'testing',
      description: '',
      color: '#f542f5',
    },
    {
      id: '4',
      title: 'scheduled',
      description: '',
      color: '#42d1f5',
    },
  ],
  savedLabels: [
    {
      id: '2',
      title: 'refund',
      description: '',
      color: '#8442f5',
    },
    {
      id: '4',
      title: 'scheduled',
      description: '',
      color: '#42d1f5',
    },
  ],
  selectedLabels: ['refund', 'scheduled'],
};
