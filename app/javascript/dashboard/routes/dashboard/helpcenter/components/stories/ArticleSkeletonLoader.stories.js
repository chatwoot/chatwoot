import ArticleSkeletonLoader from '../ArticleSearch/ArticleSkeletonLoader.vue';

export default {
  title: 'Components/Help Center/ArticleSearch/ArticleSkeletonLoader',
  component: ArticleSkeletonLoader,
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ArticleSkeletonLoader },
  template: '<article-skeleton-loader v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {};
