import { action } from '@storybook/addon-actions';
import ContactNote from './ContactNote.vue';

export default {
  title: 'Components/Notes/Note',
  component: ContactNote,
  argTypes: {
    note: {
      defaultValue:
        'A copy and paste musical notes symbols & music symbols collection for easy access.',
      control: {
        type: 'text',
      },
    },
    userName: {
      defaultValue: 'John Doe',
      control: {
        type: 'text',
      },
    },
    timeStamp: {
      defaultValue: '1618046084',
      control: {
        type: 'number',
      },
    },
    thumbnail: {
      defaultValue: 'https://randomuser.me/api/portraits/men/62.jpg',
      control: {
        type: 'text',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ContactNote },
  template:
    '<contact-note v-bind="$props" @edit="onEdit" @delete="onDelete"></contact-note>',
});

export const Note = Template.bind({});
Note.args = {
  onEdit: action('Edit'),
  onDelete: action('Delete'),
};
