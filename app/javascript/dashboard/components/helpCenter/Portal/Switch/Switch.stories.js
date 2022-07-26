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
    id: 1,
    color: null,
    custom_domain: 'doc',
    articles_count: 123,
    header_text: null,
    homepage_link: null,
    name: 'Chatwoot Docs',
    page_title: null,
    slug: 'first_portal',
    archived: false,
    config: {
      allowed_locales: [
        {
          code: 'en',
          name: 'English',
          articles_count: 123,
        },
        {
          code: 'fr',
          name: 'Français',
          articles_count: 123,
        },
        {
          code: 'de',
          name: 'Deutsch',
          articles_count: 32,
        },
        {
          code: 'es',
          name: 'Español',
          articles_count: 12,
        },
        {
          code: 'it',
          name: 'Italiano',
          articles_count: 8,
        },
      ],
    },
  },
};
