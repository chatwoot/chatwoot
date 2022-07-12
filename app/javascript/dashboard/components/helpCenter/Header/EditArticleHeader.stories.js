import { action } from '@storybook/addon-actions';
import EditArticleHeader from './EditArticleHeader';

export default {
  title: 'Components/Help Center/Header',
  component: EditArticleHeader,
  argTypes: {
    backButtonLabel: {
      defaultValue: 'Articles',
      control: {
        type: 'text',
      },
    },
    draftState: {
      defaultValue: 'saving',
      control: {
        type: 'text',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { EditArticleHeader },
  template:
    '<edit-article-header v-bind="$props" @back="onClickGoBack" @show="showPreview" @add="onClickAdd" @open="openSidebar" @close="closeSidebar" ></edit-article-header>',
});

export const EditArticleHeaderView = Template.bind({});
EditArticleHeaderView.args = {
  backButtonLabel: 'Articles',
  draftState: 'saving',
  onClickGoBack: action('goBack'),
  showPreview: action('previewOpened'),
  onClickAdd: action('added'),
  openSidebar: action('openedSidebar'),
  closeSidebar: action('closedSidebar'),
};
