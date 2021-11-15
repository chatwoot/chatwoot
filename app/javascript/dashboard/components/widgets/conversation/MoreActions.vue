<template>
  <div class="flex-container actions--container">
    <woot-button
      v-if="!currentChat.muted"
      v-tooltip="$t('CONTACT_PANEL.MUTE_CONTACT')"
      class="hollow secondary actions--button"
      icon="ion-volume-mute"
      @click="mute"
    />
    <woot-button
      v-else
      v-tooltip.left="$t('CONTACT_PANEL.UNMUTE_CONTACT')"
      class="hollow secondary actions--button"
      icon="ion-volume-medium"
      @click="unmute"
    />
    <woot-button
      v-tooltip="$t('CONTACT_PANEL.SEND_TRANSCRIPT')"
      class="hollow secondary actions--button"
      icon="ion-share"
      @click="toggleEmailActionsModal"
    />
    <resolve-action
      :conversation-id="currentChat.id"
      :status="currentChat.status"
    />
    <email-transcript-modal
      v-if="showEmailActionsModal"
      :show="showEmailActionsModal"
      :current-chat="currentChat"
      @cancel="toggleEmailActionsModal"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';
import alertMixin from 'shared/mixins/alertMixin';
import EmailTranscriptModal from './EmailTranscriptModal';
import ResolveAction from '../../buttons/ResolveAction';
import {
  CMD_MUTE_CONVERSATION,
  CMD_SEND_TRANSCRIPT,
  CMD_UNMUTE_CONVERSATION,
} from '../../../routes/dashboard/commands/commandBarBusEvents';

export default {
  components: {
    EmailTranscriptModal,
    ResolveAction,
  },
  mixins: [alertMixin, clickaway],
  data() {
    return {
      showEmailActionsModal: false,
    };
  },
  computed: {
    ...mapGetters({ currentChat: 'getSelectedChat' }),
  },
  mounted() {
    bus.$on(CMD_MUTE_CONVERSATION, this.mute);
    bus.$on(CMD_UNMUTE_CONVERSATION, this.unmute);
    bus.$on(CMD_SEND_TRANSCRIPT, this.toggleEmailActionsModal);
  },
  destroyed() {
    bus.$off(CMD_MUTE_CONVERSATION, this.mute);
    bus.$off(CMD_UNMUTE_CONVERSATION, this.unmute);
    bus.$off(CMD_SEND_TRANSCRIPT, this.toggleEmailActionsModal);
  },
  methods: {
    mute() {
      this.$store.dispatch('muteConversation', this.currentChat.id);
      this.showAlert(this.$t('CONTACT_PANEL.MUTED_SUCCESS'));
    },
    unmute() {
      this.$store.dispatch('unmuteConversation', this.currentChat.id);
      this.showAlert(this.$t('CONTACT_PANEL.UNMUTED_SUCCESS'));
    },
    toggleEmailActionsModal() {
      this.showEmailActionsModal = !this.showEmailActionsModal;
      this.hideConversationActions();
    },
  },
};
</script>
<style scoped lang="scss">
.actions--container {
  align-items: center;

  .button {
    font-size: var(--font-size-large);
    margin-right: var(--space-small);
    border-color: var(--color-border);
    color: var(--s-400);
  }
}

.more--button {
  align-items: center;
  display: flex;
  margin-left: var(--space-small);
}

.actions--container {
  position: relative;
}

.dropdown-pane {
  right: var(--space-minus-small);
  top: 48px;
}

.icon {
  margin-right: var(--space-smaller);
  min-width: var(--space-normal);
}
</style>
