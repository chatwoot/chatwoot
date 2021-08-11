import ResultItem from './ResultItem';

export default {
  title: 'Components/Search/Result Items',
  component: ResultItem,
  argTypes: {
    conversationId: {
      defaultValue: '1',
      control: {
        type: 'number',
      },
    },
    userName: {
      defaultValue: 'John davies',
      control: {
        type: 'text',
      },
    },
    inboxName: {
      defaultValue: 'Support',
      control: {
        type: 'text',
      },
    },
    timestamp: {
      defaultValue: '1618046084',
      control: {
        type: 'number',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ResultItem },
  template: '<result-item v-bind="$props"></result-item>',
});

export const ResultItems = Template.bind({});
ResultItems.args = {};
