import ContactBubble from '../bubble/Contact.vue';

export default {
  title: 'Components/Messaging/ContactBubble',
  component: ContactBubble,
  argTypes: {
    name: {
      defaultValue: 'Eden Hazard',
      control: {
        type: 'string',
      },
    },
    phoneNumber: {
      defaultValue: '+517554433220',
      control: {
        type: 'string',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ContactBubble },
  template: '<contact-bubble v-bind="$props" />',
});

export const ContactBubbleView = Template.bind({});
