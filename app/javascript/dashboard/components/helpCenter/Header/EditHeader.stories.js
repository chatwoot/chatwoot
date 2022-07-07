import { action } from '@storybook/addon-actions';
import EditArticleHeader from './EditArticleHeader';

export default {
  title: 'Components/Help Center/Article Header',
  component: EditArticleHeader,
  argTypes: {
    backButtonLabel: {
      defaultValue: 'Articles',
      control: {
        type: 'text',
      },
    },
    actionButtonLabel: {
      defaultValue: 'Publish',
      control: {
        type: 'text',
      },
    },
    isSaving: {
      defaultValue: false,
      control: {
        type: 'boolean',
      },
    },
    newChanges: {
      defaultValue: false,
      control: {
        type: 'boolean',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { EditArticleHeader },
  template:
    '<edit-article-header v-bind="$props" @goBack="onClickGoBack" @show="showPreview" @add="onClickAdd" @open="openSidebar" @close="closeSidebar" ></edit-article-header>',
});

export const EditArticleHeaderView = Template.bind({});
EditArticleHeaderView.args = {
  backButtonLabel: 'Articles',
  actionButtonLabel: 'Publish',
  isSaving: false,
  newChanges: false,
  onClickGoBack: action('goBack'),
  showPreview: action('previewOpened'),
  onClickAdd: action('added'),
  openSidebar: action('openedSidebar'),
  closeSidebar: action('closedSidebar'),
};
