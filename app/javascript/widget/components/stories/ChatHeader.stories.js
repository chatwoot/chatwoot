import { action } from '@storybook/addon-actions';
import ChatHeader from '../ChatHeader.vue';

export default {
  title: 'Components/Widgets/ChatHeader',
  component: ChatHeader,
  argTypes: {
    back: { action: 'back', description: 'Event for the "Back" button' },
    popout: { action: 'popout', description: 'Event for the "Popout" button' },
    resolve: {
      action: 'resolve',
      description: 'Event for the "Resolve" button',
    },
    showPopoutButton: {
      control: 'boolean',
      description: 'Show or hide the Popout button',
    },
    showBackButton: {
      control: 'boolean',
      description: 'Show or hide the Back button',
    },
    showResolveButton: {
      control: 'boolean',
      description: 'Show or hide the Resolve button',
    },
    isOnline: { control: 'boolean', description: 'Show online status or not' },
    avatarUrl: { control: 'text', description: 'URL for the avatar' },
    title: { control: 'text', description: 'Title of the chat' },
    body: { control: 'text', description: 'Body of the chat' },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ChatHeader },
  template:
    '<chat-header v-bind="$props" @back="onBack" @popout="onPopout" @resolve="onResolve" />',
  methods: {
    onBack: action('back'),
    onPopout: action('popout'),
    onResolve: action('resolve'),
  },
});

export const Default = Template.bind({});
Default.args = {
  avatarUrl: '',
  title: 'Chat Title',
  body: 'Chat Body',
  showPopoutButton: false,
  showBackButton: false,
  showResolveButton: false,
  isOnline: false,
};

export const WithAvatarAndButtons = Template.bind({});
WithAvatarAndButtons.args = {
  avatarUrl: 'https://via.placeholder.com/150',
  title: 'Chat Title',
  body: 'Chat Body',
  showPopoutButton: true,
  showBackButton: true,
  showResolveButton: true,
  isOnline: true,
};

export const NoAvatarWithButtons = Template.bind({});
NoAvatarWithButtons.args = {
  avatarUrl: '',
  title: 'Chat Title',
  body: 'Chat Body',
  showPopoutButton: true,
  showBackButton: true,
  showResolveButton: true,
  isOnline: true,
};
