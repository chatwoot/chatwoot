import { action } from '@storybook/addon-actions';
import ArticleHeader from './ArticleHeader';

export default {
  title: 'Components/Help Center/Header',
  component: ArticleHeader,
  argTypes: {
    headerTitle: {
      defaultValue: 'All articles',
      control: {
        type: 'text',
      },
    },
    count: {
      defaultValue: 112,
      control: {
        type: 'number',
      },
    },
    selectedValue: {
      defaultValue: 'Status',
      control: {
        type: 'text',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ArticleHeader },
  template:
    '<article-header v-bind="$props" @openModal="openFilterModal" @open="openDropdown" @close="closeDropdown" ></article-header>',
});

export const ArticleHeaderView = Template.bind({});
ArticleHeaderView.args = {
  headerTitle: 'All articles',
  count: 112,
  selectedValue: 'Status',
  openFilterModal: action('openedFilterModal'),
  openDropdown: action('opened'),
  closeDropdown: action('closed'),
};
