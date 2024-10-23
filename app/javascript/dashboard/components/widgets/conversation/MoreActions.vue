<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import EmailTranscriptModal from './EmailTranscriptModal.vue';
import ResolveAction from '../../buttons/ResolveAction.vue';
import {
  CMD_MUTE_CONVERSATION,
  CMD_SEND_TRANSCRIPT,
  CMD_UNMUTE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

export default {
  components: {
    EmailTranscriptModal,
    ResolveAction,
  },
  data() {
    return {
      showEmailActionsModal: false,
    };
  },
  computed: {
    ...mapGetters({ currentChat: 'getSelectedChat' }),
    isChatbotConnectedToInbox() {
      if (this.currentChat && this.currentChat.chatbot_attributes) {
        return !!this.currentChat.chatbot_attributes.id;
      }
      return false;
    },
    isChatbotEnabled() {
      return (
        this.currentChat?.chatbot_attributes?.status === 'Enabled' || false
      );
    },
  },
  mounted() {
    this.$emitter.on(CMD_MUTE_CONVERSATION, this.mute);
    this.$emitter.on(CMD_UNMUTE_CONVERSATION, this.unmute);
    this.$emitter.on(CMD_SEND_TRANSCRIPT, this.toggleEmailActionsModal);
  },
  destroyed() {
    this.$emitter.off(CMD_MUTE_CONVERSATION, this.mute);
    this.$emitter.off(CMD_UNMUTE_CONVERSATION, this.unmute);
    this.$emitter.off(CMD_SEND_TRANSCRIPT, this.toggleEmailActionsModal);
  },
  methods: {
    mute() {
      this.$store.dispatch('muteConversation', this.currentChat.id);
      useAlert(this.$t('CONTACT_PANEL.MUTED_SUCCESS'));
    },
    unmute() {
      this.$store.dispatch('unmuteConversation', this.currentChat.id);
      useAlert(this.$t('CONTACT_PANEL.UNMUTED_SUCCESS'));
    },
    toggleEmailActionsModal() {
      this.showEmailActionsModal = !this.showEmailActionsModal;
    },
    disableBot() {
      this.$store.dispatch('disableChatbot', this.currentChat.id);
      useAlert(this.$t('CHATBOTS.DISABLED_SUCCESS'));
    },
    enableBot() {
      this.$store.dispatch('enableChatbot', this.currentChat.id);
      useAlert(this.$t('CHATBOTS.ENABLED_SUCCESS'));
    },
  },
};
</script>

<template>
  <div class="relative flex items-center gap-2 actions--container">
    <div v-if="isChatbotConnectedToInbox">
      <woot-button
        v-if="isChatbotEnabled"
        v-tooltip.left="$t('CHATBOTS.DISABLE_BOT')"
        variant="smooth"
        color-scheme="primary"
        icon="chatbot-icon"
        @click="disableBot"
      />
      <woot-button
        v-else
        v-tooltip.left="$t('CHATBOTS.ENABLE_BOT')"
        variant="smooth"
        color-scheme="alert"
        icon="chatbot-icon"
        @click="enableBot"
      />
    </div>
    <woot-button
      v-if="!currentChat.muted"
      v-tooltip="$t('CONTACT_PANEL.MUTE_CONTACT')"
      variant="clear"
      color-scheme="secondary"
      icon="speaker-mute"
      @click="mute"
    />
    <woot-button
      v-else
      v-tooltip.left="$t('CONTACT_PANEL.UNMUTE_CONTACT')"
      variant="clear"
      color-scheme="secondary"
      icon="speaker-1"
      @click="unmute"
    />
    <woot-button
      v-tooltip="$t('CONTACT_PANEL.SEND_TRANSCRIPT')"
      variant="clear"
      color-scheme="secondary"
      icon="share"
      @click="toggleEmailActionsModal"
    />
    <ResolveAction
      :conversation-id="currentChat.id"
      :status="currentChat.status"
    />
    <EmailTranscriptModal
      v-if="showEmailActionsModal"
      :show="showEmailActionsModal"
      :current-chat="currentChat"
      @cancel="toggleEmailActionsModal"
    />
  </div>
</template>

<style scoped lang="scss">
.more--button {
  @apply items-center flex ml-2 rtl:ml-0 rtl:mr-2;
}

.dropdown-pane {
  @apply -right-2 top-12;
}

.icon {
  @apply mr-1 rtl:mr-0 rtl:ml-1 min-w-[1rem];
}
</style>
