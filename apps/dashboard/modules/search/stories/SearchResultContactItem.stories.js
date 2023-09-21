import SearchResultContactItem from '../components/SearchResultContactItem.vue';

export default {
  title: 'Components/Search/SearchResultContactItem',
  component: SearchResultContactItem,
  argTypes: {
    id: {
      defaultValue: '123',
      control: {
        type: 'text',
      },
    },
    name: {
      defaultValue: 'John Doe',
      control: {
        type: 'text',
      },
    },
    email: {
      defaultValue: 'johndoe@faster.com',
      control: {
        type: 'text',
      },
    },
    phone: {
      defaultValue: '+1 123 456 7890',
      control: {
        type: 'text',
      },
    },
    accountId: {
      defaultValue: '7890',
      control: {
        type: 'text',
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
  components: { SearchResultContactItem },
  template:
    '<search-result-contact-item v-bind="$props"></search-result-contact-item>',
});

export const ResultContactItem = Template.bind({});
