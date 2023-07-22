import { action } from '@storybook/addon-actions';
import HeroIntro from '../HeroIntro.vue';

export default {
  title: 'Components/Widgets/HeroIntro',
  component: HeroIntro,
  argTypes: {
    title: {
      defaultValue: `We're here for you 🙌`,
      control: {
        type: 'text',
      },
    },
    body: {
      defaultValue:
        'Ask us a question and we will get back to you as soon as possible.',
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
      defaultValue: 'Typically replies within a few hours',
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
