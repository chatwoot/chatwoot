import { action } from '@storybook/addon-actions';
import noteList from './NoteList';

export default {
  title: 'Components/Notes/List',
  component: noteList,
  argTypes: {},
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { noteList },
  template:
    '<note-list v-bind="$props" @addNote="onAddNote" @editNote="onEditNote" @deleteNote="onDeleteNote" @show="onClick"></note-list>',
});

export const List = Template.bind({});
List.args = {
  onClick: action('show'),
  onAddNote: action('added'),
  onEditNote: action('edit'),
  onDeleteNote: action('deleted'),
  notes: [
    {
      id: '12345',
      content:
        'It is a long established fact that a reader will be distracted.',
      user: {
        name: 'John Doe',
        thumbnail: 'https://randomuser.me/api/portraits/men/69.jpg',
      },
      created_at: 1618046084,
    },
    {
      id: '12346',
      content:
        'It is simply dummy text of the printing and typesetting industry.',
      user: {
        name: 'Pearl Cruz',
        thumbnail: 'https://randomuser.me/api/portraits/women/29.jpg',
      },
      created_at: 1616046076,
    },
  ],
};
