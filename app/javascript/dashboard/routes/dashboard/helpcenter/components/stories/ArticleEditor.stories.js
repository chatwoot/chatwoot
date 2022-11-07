import { action } from '@storybook/addon-actions';
import ArticleEditor from './ArticleEditor.vue';

export default {
  title: 'Components/Help Center',
  component: ArticleEditor,
  argTypes: {
    article: {
      defaultValue: {},
      control: {
        type: 'object',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ArticleEditor },
  template:
    '<article-editor v-bind="$props" @focus="onFocus" @blur="onBlur"></-article>',
});

export const EditArticleView = Template.bind({});
EditArticleView.args = {
  article: {
    id: '1',
    title: 'Lorem ipsum',
    content:
      'L**orem ipsum** dolor sit amet, consectetur adipiscing elit. Congue diam orci tellus *varius per cras turpis aliquet commodo dolor justo* rutrum lorem venenatis aliquet orci curae hac. Sagittis ultrices felis **`ante placerat condimentum parturient erat consequat`** sollicitudin *sagittis potenti sollicitudin* quis velit at placerat mi torquent. Dignissim luctus nulla suspendisse purus cras commodo ipsum orci tempus morbi metus conubia et hac potenti quam suspendisse feugiat. Turpis eros dictum tellus natoque laoreet lacus dolor cras interdum **vitae gravida tincidunt ultricies tempor convallis tortor rhoncus suspendisse.** Nisi lacinia etiam vivamus tellus sed taciti potenti quam praesent congue euismod mauris est eu risus convallis taciti etiam. Inceptos iaculis turpis leo porta pellentesque dictum `bibendum blandit parturient nulla leo pretium` rhoncus litora dapibus fringilla hac litora.',
  },
  onFocus: action('focus'),
  onBlur: action('blur'),
};
