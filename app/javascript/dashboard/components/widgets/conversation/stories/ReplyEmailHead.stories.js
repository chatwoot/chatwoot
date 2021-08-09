import ReplyEmailHead from '../ReplyEmailHead';

export default {
  title: 'Components/ReplyBox/EmailHead',
  component: AddReminder,
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
    '<add-reminder v-bind="$props" @add="onAdd" @click="onClick"></add-reminder>',
});

export const Add = Template.bind({});
