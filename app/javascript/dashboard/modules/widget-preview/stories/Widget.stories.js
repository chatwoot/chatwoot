import Widget from '../components/Widget';

export default {
  title: 'components/Widget',
  component: Widget,
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { Widget },
  template: '<Widget v-bind="$props" />',
});

export const DefaultWidget = Template.bind({});
DefaultWidget.args = {};
