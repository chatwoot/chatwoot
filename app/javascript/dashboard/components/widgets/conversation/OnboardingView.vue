<template>
  <div class="columns onboarding-wrap">
    <div class="onboarding">
      <woot-loading-state
        v-if="showLoader"
        :message="loadingIndicatorMessage"
      />
      <div v-else>
        <div class="features-item">
          <h1 class="page-title">Hey 👋<br />Welcome to Chatwoot!</h1>
          <p class="intro-body">
            Thanks for signing up, We want you to get the most out of Chatwoot
            so here is about chatwoot and things to do in chatwoot to make the
            experience delightful.
          </p>
          <p>
            <a href="#" class="release-note-link">
              Read our latest updates 🎉
            </a>
          </p>
        </div>
        <div class="features-item">
          <h2 class="block-title">
            <span class="emoji">💬</span>All your conversations in one place
          </h2>
          <p class="intro-body body--intented">
            View all your conversations from multiple channels like a live
            widget for your website, Facebook, Twitter, Email and more In a
            single place. You filter conversations by the incoming channel, by
            label assigned to it from the sidebar.
          </p>
        </div>
        <div class="features-item">
          <h2 class="block-title">
            <span class="emoji">☎️</span>More agents, more fun
          </h2>
          <p class="intro-body body--intented">
            View all your conversations from multiple channels like a live
            widget for your website, Facebook, Twitter, Email and more In a
            single place. You filter conversations by the incoming channel, by
            label assigned to it from the sidebar.
          </p>
          <div class="action-wrap">
            <div class="action">
              <div>
                <h4 class="sub-block-title">
                  Add a new agent to your new team 🤝
                </h4>
                <p class="body">
                  Add a new agent in your team.
                </p>
              </div>
              <div class="button-wrap">
                <router-link :to="newAgentURL" class="button tiny">
                  Add new agent
                </router-link>
              </div>
            </div>
          </div>
        </div>
        <div class="features-item">
          <h2 class="block-title"><span class="emoji">📥</span>Inboxes</h2>
          <p class="intro-body body--intented">
            View all your conversations from multiple channels like a live
            widget for your website, Facebook, Twitter, Email and more In a
            single place. You filter conversations by the incoming channel, by
            label assigned to it from the sidebar.
          </p>
          <div></div>
          <div class="action-wrap">
            <div class="action">
              <div>
                <h4 class="sub-block-title">
                  Add a new inbox in your account 👀
                </h4>
                <p class="body">
                  Create an inbox and start receiving messages .
                </p>
              </div>
              <div class="button-wrap">
                <router-link :to="newAgentURL" class="button tiny">
                  Create new inbox
                </router-link>
              </div>
            </div>
          </div>
        </div>
        <div class="features-item">
          <h2 class="block-title">
            <span class="emoji">🏷</span>Organize with Tags
          </h2>
          <p class="intro-body body--intented">
            View all your conversations from multiple channels like a live
            widget for your website, Facebook, Twitter, Email and more In a
            single place. You filter conversations by the incoming channel, by
            label assigned to it from the sidebar.
          </p>
          <div class="action-wrap">
            <div class="action">
              <div>
                <h4 class="sub-block-title">
                  Add a new inbox in your account 👀
                </h4>
                <p class="body">
                  Create an inbox and start receiving messages .
                </p>
              </div>
              <div class="button-wrap">
                <router-link :to="newAgentURL" class="button tiny">
                  Create tags
                </router-link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import adminMixin from '../../../mixins/isAdmin';
import accountMixin from '../../../mixins/account';

export default {
  mixins: [accountMixin, adminMixin],

  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      allConversations: 'getAllConversations',
      inboxesList: 'inboxes/getInboxes',
      uiFlags: 'inboxes/getUIFlags',
      loadingChatList: 'getChatListLoadingStatus',
    }),
    loadingIndicatorMessage() {
      if (this.uiFlags.isFetching) {
        return this.$t('CONVERSATION.LOADING_INBOXES');
      }
      return this.$t('CONVERSATION.LOADING_CONVERSATIONS');
    },
    newInboxURL() {
      return this.addAccountScoping('settings/inboxes/new');
    },
    newAgentURL() {
      return this.addAccountScoping('settings/agents/new');
    },
    newTagsURL() {
      return this.addAccountScoping('settings/tags/new');
    },
    showLoader() {
      return this.uiFlags.isFetching || this.loadingChatList;
    },
  },
};
</script>
<style lang="scss" scoped>
.onboarding-wrap {
  padding: var(--space-jumbo) 8rem;
  text-align: left;
  display: flex;
  align-items: center;
  justify-content: center;
}

.features-item {
  margin-bottom: var(--space-large);
}

.page-title {
  font-size: var(--font-size-bigger);
  font-weight: var(--font-weight-bold);
  margin-bottom: var(--space-one);
  letter-spacing: -0.021em;
}

.block-title {
  font-weight: var(--font-weight-bold);
  margin-bottom: var(--space-smaller);
  letter-spacing: -0.019em;
  margin-left: var(--space-minus-large);
}

.intro-body {
  font-size: var(--font-size-default);
  font-weight: var(--font-weight-normal);
  margin-bottom: var(--space-small);
  letter-spacing: -0.013em;
  line-height: 1.5;
}

.body--intented {
  /* padding-left: var(--space-large); */
}
.release-note-link {
  color: var(--w-500);
  font-size: var(--font-size-default);
  font-weight: var(--font-weight-medium);
  text-decoration: underline;
}

.emoji {
  width: var(--space-large);
  display: inline-block;
}

.action-wrap {
  display: flex;
  width: auto;
}
.action {
  display: flex;
  align-items: center;
  flex-shrink: 1;
  background: white;
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-medium);
  padding: var(--space-one) var(--space-normal);
  /* margin-left: var(--space-large); */
  width: auto;

  .sub-block-title {
    margin-bottom: 0;
  }
  .body {
    margin-bottom: 0;
    font-size: var(--font-size-small);
  }
}

.button-wrap {
  margin-left: var(--space-large);
}

.button {
  background: var(--w-50);
  color: var(--w-600);
  border-color: var(--w-100);
  font-weight: var(--font-weight-bold);
  padding: var(--space-small) var(--space-small);
  &:hover {
    color: var(--w-50);
    background: var(--w-600);
    border-color: var(--w-600);
  }
}
</style>
