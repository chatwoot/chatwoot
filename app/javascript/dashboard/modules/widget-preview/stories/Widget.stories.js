import Widget from '../components/Widget';

const ReplyTime = {
  'In a few minutes': 'in_a_few_minutes',
  'In a few hours': 'in_a_few_hours',
  'In a few day': 'in_a_day',
};

export default {
  title: 'components/Widget',
  component: Widget,
  argTypes: {
    replyTime: {
      control: {
        type: 'select',
        options: ReplyTime,
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { Widget },
  template: '<Widget v-bind="$props" />',
});

export const DefaultWidget = Template.bind({});
DefaultWidget.args = {};
