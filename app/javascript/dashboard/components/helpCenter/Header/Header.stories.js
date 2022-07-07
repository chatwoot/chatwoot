import { action } from '@storybook/addon-actions';
import ArticleHeader from './ArticleHeader';

export default {
  title: 'Components/Help Center/Article Header',
  component: ArticleHeader,
  argTypes: {
    headerTitle: {
      defaultValue: 'All articles',
      control: {
        type: 'text',
      },
    },
    count: {
      defaultValue: 100,
      control: {
        type: 'number',
      },
    },
    buttonLabel: {
      defaultValue: 'New Article',
      control: {
        type: 'text',
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

export const Header = Template.bind({});
Header.args = {
  headerTitle: 'All articles',
  count: '100',
  buttonLabel: 'New Article',
  selectedValue: 'Status',
  openFilterModal: action('openedFilterModal'),
  openDropdown: action('opened'),
  closeDropdown: action('closed'),
};
