import MessageContent from '../components/MessageContent.vue';

export default {
  title: 'Components/Search/MessageContent',
  component: MessageContent,
  argTypes: {
    content: {
      defaultValue: '123',
      control: {
        type: 'text',
      },
    },
    author: {
      defaultValue: 'John Doe',
      control: {
        type: 'text',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { MessageContent },
  template: '<message-content v-bind="$props"></message-content>',
});

export const MessageResultItem = Template.bind({});
