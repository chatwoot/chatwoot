import SearchResultConversationItem from '../components/SearchResultConversationItem.vue';

export default {
  title: 'Components/Search/SearchResultConversationItem',
  component: SearchResultConversationItem,
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
    inbox: {
      defaultValue: {
        name: 'Livechat',
        channel_type: 'Channel::WebWidget',
      },
      control: {
        type: 'object',
      },
    },
    accountId: {
      defaultValue: '7890',
      control: {
        type: 'text',
      },
    },
    createdAt: {
      defaultValue: '1677672962',
      control: {
        type: 'text',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { SearchResultConversationItem },
  template:
    '<search-result-conversation-item v-bind="$props"></search-result-conversation-item>',
});

export const ResultConversationItem = Template.bind({});
