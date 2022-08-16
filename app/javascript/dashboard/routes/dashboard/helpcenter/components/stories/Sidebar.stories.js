import { action } from '@storybook/addon-actions';
import Sidebar from '../Sidebar/Sidebar';
import Thumbnail from 'dashboard/components/widgets/Thumbnail';

export default {
  title: 'Components/Help Center/Sidebar',
  component: { Sidebar, Thumbnail },
  argTypes: {
    thumbnailSrc: {
      defaultValue: '',
      control: {
        type: 'text',
      },
    },
    headerTitle: {
      defaultValue: '',
      control: {
        type: 'text',
      },
    },
    subTitle: {
      defaultValue: '',
      control: {
        type: 'text',
      },
    },
    accessibleMenuItems: [],
    additionalSecondaryMenuItems: [],
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { Sidebar },
  template: '<sidebar v-bind="$props" @input="onSearch"></sidebar>',
});

export const HelpCenterSidebarView = Template.bind({});
HelpCenterSidebarView.args = {
  onSearch: action('search'),
  thumbnailSrc: '',
  headerTitle: 'Help Center',
  subTitle: 'English',
  accessibleMenuItems: [
    {
      icon: 'book',
      label: 'HELP_CENTER.ALL_ARTICLES',
      key: 'helpcenter_all',
      count: 199,
      toState: 'accounts/1/articles/all',
      toolTip: 'All Articles',
      toStateName: 'helpcenter_all',
    },
    {
      icon: 'pen',
      label: 'HELP_CENTER.MY_ARTICLES',
      key: 'helpcenter_mine',
      count: 112,
      toState: 'accounts/1/articles/mine',
      toolTip: 'My articles',
      toStateName: 'helpcenter_mine',
    },
    {
      icon: 'draft',
      label: 'HELP_CENTER.DRAFT',
      key: 'helpcenter_draft',
      count: 32,
      toState: 'accounts/1/articles/draft',
      toolTip: 'Draft',
      toStateName: 'helpcenter_draft',
    },
    {
      icon: 'archive',
      label: 'HELP_CENTER.ARCHIVED',
      key: 'helpcenter_archive',
      count: 10,
      toState: 'accounts/1/articles/archived',
      toolTip: 'Archived',
      toStateName: 'helpcenter_archive',
    },
  ],
  additionalSecondaryMenuItems: [
    {
      icon: 'folder',
      label: 'HELP_CENTER.CATEGORY',
      hasSubMenu: true,
      key: 'category',
      children: [
        {
          id: 1,
          label: 'Getting started',
          count: 12,
          truncateLabel: true,
          toState: 'accounts/1/articles/categories/new',
        },
        {
          id: 2,
          label: 'Channel',
          count: 19,
          truncateLabel: true,
          toState: 'accounts/1/articles/categories/channel',
        },
        {
          id: 3,
          label: 'Feature',
          count: 24,
          truncateLabel: true,
          toState: 'accounts/1/articles/categories/feature',
        },
        {
          id: 4,
          label: 'Advanced',
          count: 8,
          truncateLabel: true,
          toState: 'accounts/1/articles/categories/advanced',
        },
        {
          id: 5,
          label: 'Mobile app',
          count: 3,
          truncateLabel: true,
          toState: 'accounts/1/articles/categories/mobile-app',
        },
        {
          id: 6,
          label: 'Others',
          count: 39,
          truncateLabel: true,
          toState: 'accounts/1/articles/categories/others',
        },
      ],
    },
  ],
};
