import { action } from '@storybook/addon-actions';
import LabelSelector from './LabelSelector';

export default {
  title: 'Components/Label/Contact Label',
  component: LabelSelector,
  argTypes: {
    contactId: {
      control: {
        type: 'text ,number',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { LabelSelector },
  template:
    '<label-selector v-bind="$props" @add="onAdd" @remove="onRemove"></label-selector>',
});

export const ContactLabel = Template.bind({});
ContactLabel.args = {
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
};
