<template>
  <div id="app" class="woot-widget-wrap">
    <router-view />
  </div>
</template>

<script>
import { mapActions, mapState } from 'vuex';
import { DEFAULT_CONVERSATION } from 'widget/store/modules/conversation';

export default {
  name: 'App',

  methods: {
    ...mapActions('auth', ['initWidget', 'initContact', 'fetchContact']),
    ...mapActions('conversation', [
      'initConversations',
      'fetchOldConversations',
    ]),

    initIframe() {
      const self = this;
      window.addEventListener('message', e => {
        if (typeof e.data === 'string' && e.data.includes('initIframe')) {
          const { data } = JSON.parse(e.data);
          const { inboxId, accountId, contact, lastConversation } = data;
          const isContactEmpty =
            contact === 'undefined' || !contact || contact === '{}';
          const conversationId = lastConversation || DEFAULT_CONVERSATION;
          self.initContact(isContactEmpty ? '{}' : JSON.parse(contact));
          self.initWidget(data);
          self.initConversations(conversationId);
          if (conversationId !== DEFAULT_CONVERSATION) {
            self.fetchOldConversations({ lastConversation });
          }
          if (isContactEmpty) {
            self.fetchContact({ inboxId, accountId });
          } else {
            // const parsedContact = JSON.parse(contact);
            // const { chat_channel: chatChannel } = parsedContact;
          }
        }
      });
    },
  },

  computed: {
    ...mapState({
      accountId: 'auth/accountId',
      inboxId: 'auth/inboxId',
    }),
  },

  mounted() {
    this.initIframe();
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/woot.scss';
</style>
