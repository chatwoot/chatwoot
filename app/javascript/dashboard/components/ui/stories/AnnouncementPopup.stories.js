import { action } from '@storybook/addon-actions';
import WootAnnouncementPopup from '../AnnouncementPopup.vue';

export default {
  title: 'Components/Popup/Announcement Popup',
  argTypes: {
    popupMessage: {
      defaultValue:
        'Now a new key shortcut (⌘ + ↵) is available to send messages. You can enable it in the',
      control: {
        type: 'text',
      },
    },
    routeText: {
      defaultValue: 'profile settings',
      control: {
        type: 'text',
      },
    },
    hasCloseButton: {
      defaultValue: true,
      control: {
        type: 'boolean',
      },
    },
    closeButtonText: {
      defaultValue: 'Got it',
      control: {
        type: 'text',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { WootAnnouncementPopup },
  template:
    '<woot-announcement-popup v-bind="$props" @open="onClickOpenPath" @close="onClickClose"></woot-announcement-popup>',
});

export const AnnouncementPopup = Template.bind({});
AnnouncementPopup.args = {
  onClickOpenPath: action('opened path'),
  onClickClose: action('closed the popup'),
};
