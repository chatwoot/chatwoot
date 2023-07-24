import { action } from '@storybook/addon-actions';
import ArticleHero from '../ArticleHero.vue'; // adjust this path to match your file's location

export default {
  title: 'Components/Widgets/ArticleHero',
  component: ArticleHero,
  argTypes: {
    search: { action: 'search', description: 'Event for the "Search" input' },
    articles: { control: 'array', description: 'Array of articles' },
    categoryPath: { control: 'text', description: 'Path to the category' },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ArticleHero },
  template: '<article-hero v-bind="$props" @search="search" />',
  methods: {
    search: action('search'),
  },
});

export const Default = Template.bind({});
Default.args = {
  articles: [
    { title: 'Article 1', content: 'This is article 1.' },
    { title: 'Article 2', content: 'This is article 2.' },
    { title: 'Article 3', content: 'This is article 3.' },
    { title: 'Article 4', content: 'This is article 4.' },
  ],
  categoryPath: '/some/path',
};
