import { action } from '@storybook/addon-actions';
import AllPortals from '../AllPortals';

export default {
  title: 'Components/Help Center/Portal List',
  component: AllPortals,
  argTypes: {
    portals: { control: 'array' },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { AllPortals },
  template:
    '<all-portals v-bind="$props" @create-portal="createPortal" ></all-portals>',
});

export const AllPortalsView = Template.bind({});
AllPortalsView.args = {
  createPortal: action('open-create-portal-view'),
  portals: [
    {
      name: 'Chatwoot Help Center',
      id: 1,
      color: 'red',
      custom_domain: 'help-center.chatwoot.com',
      articles_count: 123,
      header_text: 'Help center',
      homepage_link: null,
      page_title: 'English',
      slug: 'help-center',
      archived: false,
      config: {
        allowed_locales: [
          {
            code: 'en-US',
            name: 'English',
            articles_count: 123,
            categories_count: 42,
          },
          {
            code: 'fr-FR',
            name: 'Français',
            articles_count: 23,
            categories_count: 11,
          },
          {
            code: 'de-DE',
            name: 'Deutsch',
            articles_count: 32,
            categories_count: 12,
          },
          {
            code: 'es-ES',
            name: 'Español',
            articles_count: 12,
            categories_count: 4,
          },
        ],
      },
      locales: [
        {
          code: 'en-US',
          name: 'English',
          articles_count: 123,
          categories_count: 42,
        },
        {
          code: 'fr-FR',
          name: 'Français',
          articles_count: 23,
          categories_count: 11,
        },
        {
          code: 'de-DE',
          name: 'Deutsch',
          articles_count: 32,
          categories_count: 12,
        },
        {
          code: 'es-ES',
          name: 'Español',
          articles_count: 12,
          categories_count: 4,
        },
      ],
    },
    {
      name: 'Chatwoot Docs',
      id: 2,
      color: 'green',
      custom_domain: 'doc-chatwoot.com',
      articles_count: 67,
      header_text: 'Docs',
      homepage_link: null,
      page_title: 'Portal',
      slug: 'second_portal',
      archived: false,
      config: {
        allowed_locales: [
          {
            name: 'English',
            code: 'en-EN',
            articles_count: 12,
            categories_count: 66,
          },
          {
            name: 'Mandarin',
            code: 'ch-CH',
            articles_count: 6,
            categories_count: 23,
          },
        ],
      },
      locales: [
        {
          name: 'English',
          code: 'en-EN',
          articles_count: 12,
          categories_count: 66,
        },
        {
          name: 'Mandarin',
          code: 'ch-CH',
          articles_count: 6,
          categories_count: 23,
        },
      ],
    },
  ],
};
