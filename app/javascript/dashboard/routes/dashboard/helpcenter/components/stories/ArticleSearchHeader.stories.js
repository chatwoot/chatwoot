import ArticleSearchHeader from '../ArticleSearch/Header';

export default {
  title: 'Components/Help Center/ArticleSearch/Header',
  component: ArticleSearchHeader,
  argTypes: {
    title: {
      defaultValue: 'Insert article',
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
  components: { ArticleSearchHeader },
  template: '<article-search-header v-bind="$props"></article-search-header>',
});

export const ArticleHeaderView = Template.bind({});
ArticleHeaderView.args = {
  title: 'Insert article',
};
