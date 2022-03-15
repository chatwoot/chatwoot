<template>
  <div class="conversation-details-wrap">
    <conversation-header
      v-if="currentChat.id"
      :chat="currentChat"
      :is-contact-panel-open="isContactPanelOpen"
      @contact-panel-toggle="onToggleContactPanel"
    />
    <div class="messages-and-sidebar">
      <messages-view
        v-if="currentChat.id"
        :inbox-id="inboxId"
        :is-contact-panel-open="isContactPanelOpen"
        @contact-panel-toggle="onToggleContactPanel"
      />
      <empty-state v-else />

      <div v-show="showContactPanel" class="conversation-sidebar-wrap">
        <contact-panel
          v-if="showContactPanel"
          :conversation-id="currentChat.id"
          :inbox-id="currentChat.inbox_id"
          :on-toggle="onToggleContactPanel"
        />
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import ContactPanel from 'dashboard/routes/dashboard/conversation/ContactPanel';
import ConversationHeader from './ConversationHeader';
import EmptyState from './EmptyState';
import MessagesView from './MessagesView';

export default {
  components: {
    EmptyState,
    MessagesView,
    ContactPanel,
    ConversationHeader,
  },

  props: {
    inboxId: {
      type: [Number, String],
      default: '',
      required: false,
    },
    isContactPanelOpen: {
      type: Boolean,
      default: true,
    },
  },
  computed: {
    ...mapGetters({ currentChat: 'getSelectedChat' }),
    showContactPanel() {
      return this.isContactPanelOpen && this.currentChat.id;
    },
  },
  watch: {
    'currentChat.inbox_id'(inboxId) {
      if (inboxId) {
        this.$store.dispatch('inboxAssignableAgents/fetch', { inboxId });
      }
    },
    'currentChat.id'() {
      this.fetchLabels();
    },
  },
  mounted() {
    this.fetchLabels();
  },
  methods: {
    fetchLabels() {
      if (!this.currentChat.id) {
        return;
      }
      this.$store.dispatch('conversationLabels/get', this.currentChat.id);
    },
    onToggleContactPanel() {
      this.$emit('contact-panel-toggle');
    },
  },
};
</script>
<style lang="scss" scoped>
@import '~dashboard/assets/scss/woot';

.conversation-details-wrap {
  display: flex;
  flex-direction: column;
  min-width: 0;
  width: 100%;
  border-left: 1px solid var(--color-border);
  background: var(--color-background-light);
}

.messages-and-sidebar {
  display: flex;
  background: var(--color-background-light);
  margin: 0;
  height: 100%;
  min-height: 0;
}

.conversation-sidebar-wrap {
  height: auto;
  flex: 0 0;
  overflow: hidden;
  overflow: auto;
  background: white;
  flex-basis: 28rem;

  @include breakpoint(large up) {
    flex-basis: 30em;
  }

  @include breakpoint(xlarge up) {
    flex-basis: 31em;
  }

  @include breakpoint(xxlarge up) {
    flex-basis: 33rem;
  }

  @include breakpoint(xxxlarge up) {
    flex-basis: 40rem;
  }

  &::v-deep .contact--panel {
    width: 100%;
    height: 100%;
    max-width: 100%;
  }
}
</style>
