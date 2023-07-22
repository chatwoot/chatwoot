import { action } from '@storybook/addon-actions';
import TopBar from '../TopBar.vue';

export default {
  title: 'Components/Widgets/TopBar',
  component: TopBar,
  argTypes: {
    back: {
      action: 'clicked',
      description: 'Event for the "Back" button',
    },
    close: {
      action: 'clicked',
      description: 'Event for the "Close" button',
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { TopBar },
  template: '<top-bar @back="onBack" @close="onClose" />',
  methods: {
    onBack: action('back'),
    onClose: action('close'),
  },
});

export const BackButton = Template.bind({});
BackButton.args = {};

export const CloseButton = Template.bind({});
CloseButton.args = {};
