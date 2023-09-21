import ArticleTableComponent from '../ArticleTable.vue';
import { action } from '@storybook/addon-actions';
export default {
  title: 'Components/Help Center',
  component: ArticleTableComponent,
  argTypes: {
    articles: {
      defaultValue: [],
      control: {
        type: 'array',
      },
    },
    articleCount: {
      defaultValue: 10,
      control: {
        type: 'number',
      },
    },
    currentPage: {
      defaultValue: 1,
      control: {
        type: 'number',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ArticleTableComponent },
  template:
    '<article-table-component @onPageChange="onPageChange" v-bind="$props" ></article-table-component>',
});

export const ArticleTable = Template.bind({});
ArticleTable.args = {
  articles: [
    {
      title: 'Setup your account',
      author: {
        name: 'John Doe',
      },
      readCount: 13,
      category: 'Getting started',
      status: 'published',
      updatedAt: 1657255863,
    },
    {
      title: 'Docker Configuration',
      author: {
        name: 'Sam Manuel',
      },
      readCount: 13,
      category: 'Engineering',
      status: 'draft',
      updatedAt: 1656658046,
    },
    {
      title: 'Campaigns',
      author: {
        name: 'Sam Manuel',
      },
      readCount: 28,
      category: 'Engineering',
      status: 'archived',
      updatedAt: 1657590446,
    },
  ],
  articleCount: 10,
  currentPage: 1,
  onPageChange: action('onPageChange'),
};
