import Vue from 'vue';
import VTooltip from 'v-tooltip';
import CsatMetricCard from './CsatMetricCard';

Vue.use(VTooltip, { defaultHtml: false });

export default {
  title: 'Components/CSAT/Metrics Card',
  component: CsatMetricCard,
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
  components: { CsatMetricCard },
  template: '<csat-metric-card v-bind="$props" />',
});

export const CsatMetricCardTemplate = Template.bind({});
CsatMetricCardTemplate.args = {
  infoText: 'No. of responses / No. of survey messages sent * 100',
  label: 'Satisfaction Score',
  value: '98.5',
};
