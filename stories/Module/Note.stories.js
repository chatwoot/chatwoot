import { action } from '@storybook/addon-actions';
import Note from '../../app/javascript/dashboard/routes/dashboard/contacts/components/ContactNote';

export default {
  title: 'Components/Note',
  component: Note,
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
  components: { Note },
  template: '<note v-bind="$props" @edit="onEdit" @delete="onDelete" ></note>',
});

export const DefaultNote = Template.bind({});
DefaultNote.args = {
  onEdit: action('Edit'),
  onDelete: action('Delete'),
};
