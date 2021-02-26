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
}

.conversation-sidebar-wrap {
  height: calc(100vh - 63px);
  overflow: auto;
  background: white;

  @include breakpoint(large up) {
    max-width: 33rem;
  }
  @include breakpoint(xlarge up) {
    max-width: 31rem;
  }
  @include breakpoint(xxlarge up) {
    max-width: 37rem;
  }

  &::v-deep .contact--panel {
    width: 100%;
    height: 100%;
    max-width: 100%;
  }
}
</style>
