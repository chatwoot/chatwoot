import { action } from '@storybook/addon-actions';
import ArticleHero from '../ArticleHero.vue'; // adjust this path to match your file's location

export default {
  title: 'Components/Widgets/ArticleHero',
  component: ArticleHero,
  argTypes: {
    articles: { control: 'array', description: 'Array of articles' },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ArticleHero },
  template:
    '<article-hero v-bind="$props" @view-all-articles="viewAllArticles" />',
  methods: {
    viewAllArticles: action('view-all-articles'),
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
};
