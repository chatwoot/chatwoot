import TimeAgo from 'dashboard/components/ui/TimeAgo';

export default {
  title: 'Components/TimeAgo',
  component: TimeAgo,
  argTypes: {
    isAutoRefreshEnabled: {
      control: {
        type: 'boolean',
      },
    },
    timestamp: {
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
  timestamp: 1549843200,
  isAutoRefreshEnabled: false,
};
