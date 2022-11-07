import Thumbnail from './Thumbnail.vue';

export default {
  title: 'Components/Thumbnail',
  component: Thumbnail,
  argTypes: {
    src: {
      control: {
        type: 'text',
      },
    },
    size: {
      control: {
        type: 'text',
      },
    },
    badge: {
      control: {
        type: 'select',
        options: ['fb', 'whatsapp', 'sms', 'twitter-tweet', 'twitter-dm'],
      },
    },
    variant: {
      control: {
        type: 'select',
        options: ['circle', 'square'],
      },
    },
    username: {
      defaultValue: 'John Doe',
      control: {
        type: 'text',
      },
    },
    status: {
      defaultValue: 'circle',
      control: {
        type: 'select',
        options: ['online', 'busy'],
      },
    },
    hasBorder: {
      control: {
        type: 'boolean',
      },
    },
    shouldShowStatusAlways: {
      control: {
        type: 'boolean',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { Thumbnail },
  template: '<thumbnail v-bind="$props" @click="onClick">{{label}}</thumbnail>',
});

export const Primary = Template.bind({});
