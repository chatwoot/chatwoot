import TimeAgo from 'dashboard/components/ui/TimeAgo';

export default {
  title: 'Components/TimeAgo',
  component: TimeAgo,
  argTypes: {
    refresh: {
      control: {
        type: 'boolean, number',
      },
    },
    datetime: {
      control: {
        type: 'text, date, number',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { TimeAgo },
  template: '<time-ago v-bind="$props"></time-ago>',
});

export const TimeAgoView = Template.bind({});
TimeAgoView.args = {
  datetime: 1549843200,
  refresh: false,
};
