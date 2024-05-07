<template>
  <div class="flex actions--container relative items-center gap-2">
    <woot-button
        v-if="enableSmartActions"
        variant="hollow"
        color-scheme="secondary"
        icon="star-glitters"
        @click="toggleSmartActions"
      >
      Smart Actions
    </woot-button>
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
    <transition name="slide" :duration="{ enter: 1000, leave: 1000, delay: 3000 }">
      <smart-actions></smart-actions>
    </transition>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';
import alertMixin from 'shared/mixins/alertMixin';
import EmailTranscriptModal from './EmailTranscriptModal.vue';
import ResolveAction from '../../buttons/ResolveAction.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import SmartActions from './SmartActions.vue';
import inboxMixin from 'shared/mixins/inboxMixin';

import {
  CMD_MUTE_CONVERSATION,
  CMD_SEND_TRANSCRIPT,
  CMD_UNMUTE_CONVERSATION,
} from '../../../routes/dashboard/commands/commandBarBusEvents';

export default {
  components: {
    EmailTranscriptModal,
    ResolveAction,
    SmartActions,
  },
  mixins: [alertMixin, clickaway, inboxMixin],
  data() {
    return {
      showEmailActionsModal: false,
    };
  },
  computed: {
    ...mapGetters({ 
      isFeatureEnabledGlobally: 'accounts/isFeatureEnabledGlobally',
      currentChat: 'getSelectedChat',
      accountId: 'getCurrentAccountId',
      showSmartActions: 'showSmartActions',
    }),
    enableSmartActions() {
      const isFeatEnabled = this.isFeatureEnabledGlobally(
        this.accountId,
        FEATURE_FLAGS.SMART_ACTIONS
      );
      return isFeatEnabled && (this.isAnEmailChannel || this.isAWebWidgetInbox);
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.currentChat.inbox_id);
    },
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
    },
    toggleSmartActions(){
      const conversationId =  this.currentChat.id;
      const messageId = null;
      this.$store.dispatch('getSmartActions', { conversationId, messageId });
      this.$store.dispatch('showSmartActions', true);
    },
  },
};
</script>
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
