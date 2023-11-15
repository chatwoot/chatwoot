import ArticleSearchResultItem from '../ArticleSearch/ArticleSearchResultItem.vue';

export default {
  title: 'Components/Help Center/ArticleSearchResultItem',
  component: ArticleSearchResultItem,
  argTypes: {
    title: {
      defaultValue: 'Setup your account',
      control: {
        type: 'text',
      },
    },
    body: {
      defaultValue:
        'You can integrate your Chatwoot account with multiple conversation channels like website live-chat, email, Facebook page, Twitter handle, WhatsApp, etc. You can view all of your conversations from different channels on one dashboard. This helps in reducing the time and friction involved with switching between multiple tools.',
      control: {
        type: 'text',
      },
    },
    category: {
      defaultValue: 'Getting started',
      control: {
        type: 'text',
      },
    },
    locale: {
      defaultValue: 'en-US',
      control: {
        type: 'text',
      },
    },
    url: {
      defaultValue: '/app/accounts/1/conversations/23842',
      control: {
        type: 'text',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ArticleSearchResultItem },
  template:
    '<ArticleSearchResultItem v-bind="$props" ></ArticleSearchResultItem>',
});

export const ArticleSearchResultItemStory = Template.bind({});
ArticleSearchResultItemStory.args = {
  title: 'Setup your account',
  body: `You can integrate your Chatwoot account with multiple conversation channels like website live-chat, email, Facebook page, Twitter handle, WhatsApp, etc. You can view all of your conversations from different channels on one dashboard. This helps in reducing the time and friction involved with switching between multiple tools.

You can manage your conversations and collaborate with your team on the go with Chatwoot mobile apps (available for Android and iOS).

In this user guide, we’ve explained the features, capabilities, modes of operation, and step-by-step procedures for easily using the Chatwoot platform.`,
};
