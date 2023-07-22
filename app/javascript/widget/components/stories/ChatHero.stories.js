import { action } from '@storybook/addon-actions';
import ChatHero from '../ChatHero.vue';

export default {
  title: 'Components/Widgets/ChatHero',
  component: ChatHero,
  argTypes: {
    hasConversation: {
      defaultValue: false,
      control: {
        type: 'boolean',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ChatHero },
  onAllChats: action('clicked'),
  template:
    '<ChatHero v-bind="$props" @start="onStart" @all-chats="">Hello world!</ChatHero>',
});

export const DefaultChatHero = Template.bind({});
DefaultChatHero.args = {
  onStart: action('clicked'),
  onAllChats: action('clicked'),
};
