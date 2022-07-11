import ArticleTableComponent from './ArticleTable.vue';

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
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ArticleTableComponent },
  template:
    '<article-table-component v-bind="$props" ></article-table-component>',
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
      updatedAt: 1617255863,
    },
    {
      title: 'Campaigns',
      author: {
        name: 'Sam Manuel',
      },
      readCount: 28,
      category: 'Engineering',
      status: 'archived',
      updatedAt: 1652255263,
    },
  ],
};
