import ArticleSearchArticleView from '../ArticleSearch/ArticleView';

export default {
  title: 'Components/Help Center/ArticleSearch/ArticleView',
  component: ArticleSearchArticleView,
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
  components: { ArticleSearchArticleView },
  template:
    '<article-search-article-view v-bind="$props"></article-search-article-view>',
});

export const ArticleHeaderView = Template.bind({});
ArticleHeaderView.args = {
  title: 'Insert article',
  url: 'https://staging.chatwoot.com/hc/home-rental-app/articles/filter-your-housing-search-results-0',
};
