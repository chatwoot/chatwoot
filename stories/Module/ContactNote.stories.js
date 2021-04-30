import { action } from '@storybook/addon-actions';
import ContactNote from '../../app/javascript/dashboard/routes/dashboard/contacts/components/ContactNote';

export default {
  title: 'Components/Notes/Note',
  component: ContactNote,
  argTypes: {
    note: {
      control: {
        type: 'text',
      },
    },
    userName: {
      control: {
        type: 'text',
      },
    },
    timeStamp: {
      control: {
        type: 'number',
      },
    },
    thumbnail: {
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
    '<contact-note v-bind="$props" @edit="onEdit" @delete="onDelete">{{note}}{{userName}}{{timeStamp}}{{thumbnail}}</contact-note>',
});

export const Note = Template.bind({});
Note.args = {
  note:
    'A copy and paste musical notes symbols & music symbols collection for easy access.',
  userName: 'John Doe',
  timeStamp: '1618046084',
  thumbnail: 'https://randomuser.me/api/portraits/men/62.jpg',
  onEdit: action('Edit'),
  onDelete: action('Delete'),
};
