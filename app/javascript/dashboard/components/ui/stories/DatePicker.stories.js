import { action } from '@storybook/addon-actions';
import WootDatePicker from '../DatePicker.vue';

export default {
  title: 'Components/Date Picker',
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
    showRange: {
      defaultValue: false,
      control: {
        type: 'checkbox',
      },
    },
    type: {
      control: {
        type: 'select',
        options: ['datetime', 'date'],
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { WootDatePicker },
  template:
    '<woot-date-picker v-bind="$props" @change="onChange"></woot-date-picker>',
});

export const DateTimePicker = Template.bind({});
DateTimePicker.args = {
  onChange: action('applied'),
  value: new Date(),
  type: 'datetime',
  placeholder: 'Select date time',
};

export const DateRangePicker = Template.bind({});
DateRangePicker.args = {
  onChange: action('applied'),
  value: [new Date(), new Date()],
  showRange: true,
};
