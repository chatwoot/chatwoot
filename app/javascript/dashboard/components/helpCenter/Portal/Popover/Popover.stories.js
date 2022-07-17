import PortalPopover from './Index.vue';

export default {
  title: 'Components/Help Center/Portal Popover',
  component: PortalPopover,
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
  components: { PortalPopover },
  template:
    '<PortalPopover v-bind="$props" @click="onClick">{{label}}</PortalPopover>',
});

export const Primary = Template.bind({});

Primary.args = {
  portals: [
    {
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
    {
      name: 'Chatwoot Docs',
      article_count: 16,
      locales: [
        {
          name: 'English',
          code: 'en',
          article_count: 12,
        },
        {
          name: 'Japanese',
          code: 'jp',
          article_count: 4,
        },
        {
          name: 'Mandarin',
          code: 'CH',
          article_count: 6,
        },
      ],
    },
  ],
};
