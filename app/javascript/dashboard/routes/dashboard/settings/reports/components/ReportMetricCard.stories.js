import Vue from 'vue';
import VTooltip from 'v-tooltip';
import ReportMetricCard from './ReportMetricCard';

Vue.use(VTooltip, { defaultHtml: false });

export default {
  title: 'Components/CSAT/Metrics Card',
  component: ReportMetricCard,
  argTypes: {
    label: {
      defaultValue: '',
      control: {
        type: 'text',
      },
    },
    value: {
      defaultValue: '',
      control: {
        type: 'text',
      },
    },
    infoText: {
      defaultValue: '',
      control: {
        type: 'text',
      },
    },
  },
};

const Template = (_, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ReportMetricCard },
  template: '<report-metric-card v-bind="$props" />',
});

export const ReportMetricCardTemplate = Template.bind({});
ReportMetricCardTemplate.args = {
  infoText: 'No. of responses / No. of survey messages sent * 100',
  label: 'Satisfaction Score',
  value: '98.5',
};
