import SearchMessage from './SearchMessageItem';

export default {
  title: 'Components/Search/Messages',
  component: SearchMessage,
  argTypes: {
    userName: {
      defaultValue: 'John davies',
      control: {
        type: 'text',
      },
    },
    timestamp: {
      defaultValue: '1618046084',
      control: {
        type: 'number',
      },
    },
    messageType: {
      control: {
        type: 'number',
      },
    },
    content: {
      defaultValue:
        'some designers and developers around the web know this and have put together a bunch of text generators',
      control: {
        type: 'text',
      },
    },
    searchTerm: {
      defaultValue: 'developers',
      control: {
        type: 'text',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { SearchMessage },
  template: '<search-message v-bind="$props"></-item>',
});

export const Messages = Template.bind({});
Messages.args = {};
