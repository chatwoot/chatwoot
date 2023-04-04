import InboxDropdownItem from './InboxDropdownItem';

export default {
  title: 'Components/DropDowns/InboxDropdownItem',
  component: InboxDropdownItem,
  argTypes: {
    name: {
      defaultValue: 'My new inbox',
      control: {
        type: 'text',
      },
    },

    inboxIdentifier: {
      defaultValue: 'nithin@mail.com',
      control: {
        type: 'text',
      },
    },

    channelType: {
      defaultValue: 'email',
      control: {
        type: 'text',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { InboxDropdownItem },
  template: '<inbox-dropdown-item v-bind="$props" ></inbox-dropdown-item>',
});

export const Banner = Template.bind({});
Banner.args = {};
