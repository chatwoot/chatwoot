import PortalSwitch from './Index.vue';

export default {
  title: 'Components/Help Center/Portal Switch',
  component: PortalSwitch,
  argTypes: {
    active: {
      defaultValue: false,
      control: {
        type: 'boolean',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { PortalSwitch },
  template:
    '<PortalSwitch v-bind="$props" @click="onClick">{{label}}</PortalSwitch>',
});

export const Primary = Template.bind({});

Primary.args = {
  active: false,
  portal: {
    name: 'Chatwoot Help Center',
    article_count: 124,
    locales: [
      {
        name: 'English',
        code: 'en',
        article_count: 12,
      },
      {
        name: 'Español',
        code: 'es',
        article_count: 42,
      },
      {
        name: 'French',
        code: 'fr',
        article_count: 29,
      },
      {
        name: 'Italian',
        code: 'it',
        article_count: 4,
      },
      {
        name: 'German',
        code: 'de',
        article_count: 66,
      },
    ],
  },
};
