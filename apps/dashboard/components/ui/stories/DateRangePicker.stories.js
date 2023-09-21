import { action } from '@storybook/addon-actions';
import WootDateRangePicker from '../DateRangePicker.vue';

export default {
  title: 'Components/Date Picker/Date Range Picker',
  argTypes: {
    confirmText: {
      defaultValue: 'Apply',
      control: {
        type: 'text',
      },
    },
    placeholder: {
      defaultValue: 'Select date range',
      control: {
        type: 'text',
      },
    },
    value: {
      control: {
        type: 'text',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { WootDateRangePicker },
  template:
    '<woot-date-range-picker v-bind="$props" @change="onChange"></woot-date-range-picker>',
});

export const DateRangePicker = Template.bind({});
DateRangePicker.args = {
  onChange: action('applied'),
  value: new Date(),
};
