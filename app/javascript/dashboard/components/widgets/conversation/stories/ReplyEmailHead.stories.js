import ReplyEmailHead from '../ReplyEmailHead';

export default {
  title: 'Components/ReplyBox/EmailHead',
  component: ReplyEmailHead,
  argTypes: {
    ccEmails: {
      control: {
        type: 'string',
      },
    },
    bccEmails: {
      control: {
        type: 'string',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ReplyEmailHead },
  template:
    '<reply-email-head v-bind="$props" @add="onAdd" @click="onClick"></reply-email-head>',
});

export const Add = Template.bind({});
