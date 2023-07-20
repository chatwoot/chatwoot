import { action } from '@storybook/addon-actions';
import HeroIntro from '../HeroIntro.vue';

export default {
  title: 'Components/Widgets/HeroIntro',
  component: HeroIntro,
  argTypes: {
    title: {
      defaultValue: 'sales',
      control: {
        type: 'text',
      },
    },
    body: {
      defaultValue: 'sales',
      control: {
        type: 'text',
      },
    },
    agents: {
      control: {
        type: 'select',
        options: [{ id: 1, name: 'David' }],
      },
    },
    replyWaitMessage: {
      defaultValue: 'Please wait',
      control: {
        type: 'text',
      },
    },
    isOnline: {
      defaultValue: false,
      control: {
        type: 'boolean',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { HeroIntro },
  template: '<HeroIntro v-bind="$props" @start="onStart"></HeroIntro>',
});

export const DefaultHeroIntro = Template.bind({});
DefaultHeroIntro.args = {
  onStart: action('clicked'),
};
