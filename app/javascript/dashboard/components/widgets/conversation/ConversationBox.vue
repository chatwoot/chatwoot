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
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    showContactPanel() {
      return this.isContactPanelOpen && this.currentChat.id;
    },
  },
  methods: {
    onToggleContactPanel() {
      this.$emit('contact-panel-toggle');
    },
  },
};
</script>
<style lang="scss" scoped>
@import '~dashboard/assets/scss/app.scss';

.conversation-details-wrap {
  display: flex;
  flex-direction: column;
  width: 100%;
  border-left: 1px solid var(--color-border);
}

.messages-and-sidebar {
  display: flex;
  background: var(--color-background-light);
  margin: 0;
  height: auto;
  flex: 1 1;
  overflow: hidden;
}

.conversation-sidebar-wrap {
  height: auto;
  flex: 0 1;
  overflow: hidden;
  overflow: auto;
  background: white;
  flex-shrink: 0;
  flex-basis: 28rem;

  @include breakpoint(large up) {
    flex-basis: 31em;
  }

  @include breakpoint(xlarge up) {
    flex-basis: 32em;
  }

  @include breakpoint(xxlarge up) {
    flex-basis: 36rem;
  }

  &::v-deep .contact--panel {
    width: 100%;
    height: 100%;
    max-width: 100%;
  }
}
</style>
