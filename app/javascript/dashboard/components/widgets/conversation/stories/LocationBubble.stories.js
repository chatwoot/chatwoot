import LocationBubble from '../bubble/Location.vue';

export default {
  title: 'Components/Help Center',
  component: LocationBubble,
  argTypes: {
    latitude: {
      defaultValue: 1,
      control: {
        type: 'number',
      },
    },
    longitude: {
      defaultValue: 1,
      control: {
        type: 'number',
      },
    },
    name: {
      defaultValue: '420, Dope street',
      control: {
        type: 'string',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { LocationBubble },
  template: '<location-bubble v-bind="$props" />',
});

export const LocationBubbleView = Template.bind({});
