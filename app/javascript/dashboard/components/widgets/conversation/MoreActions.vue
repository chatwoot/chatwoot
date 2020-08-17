<template>
  <div class="flex-container actions--container">
    <resolve-action
      :conversation-id="currentChat.id"
      :status="currentChat.status"
    />
    <woot-button
      class="success hollow more--button"
      icon="ion-more"
      :class="buttonClass"
      @click="toggleConversationActions"
    />
    <div
      v-if="showConversationActions"
      v-on-clickaway="hideConversationActions"
      class="dropdown-pane"
      :class="{ 'dropdown-pane--open': showConversationActions }"
    >
      <button
        v-if="!currentChat.muted"
        class="button small clear row nice alert small-6 action--button"
        @click="mute"
      >
        <i class="icon ion-volume-mute" />
        <span>{{ $t('CONTACT_PANEL.MUTE_CONTACT') }}</span>
      </button>
      <button
        class="button small clear row nice small-6 action--button"
        @click="toggleEmailActionsModal"
      >
        <i class="icon ion-ios-copy" />
        {{ $t('CONTACT_PANEL.SEND_TRANSCRIPT') }}
      </button>
    </div>
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
import wootConstants from '../../../constants';

export default {
  components: {
    EmailTranscriptModal,
    ResolveAction,
  },
  mixins: [alertMixin, clickaway],
  data() {
    return {
      showConversationActions: false,
      showEmailActionsModal: false,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),

    buttonClass() {
      return this.currentChat.status !== wootConstants.STATUS_TYPE.OPEN
        ? 'warning'
        : 'success';
    },
  },
  methods: {
    mute() {
      this.$store.dispatch('muteConversation', this.currentChat.id);
      this.showAlert(this.$t('CONTACT_PANEL.MUTED_SUCCESS'));
      this.toggleConversationActions();
    },
    toggleEmailActionsModal() {
      this.showEmailActionsModal = !this.showEmailActionsModal;
      this.hideConversationActions();
    },
    toggleConversationActions() {
      this.showConversationActions = !this.showConversationActions;
    },
    hideConversationActions() {
      this.showConversationActions = false;
    },
  },
};
</script>
<style scoped lang="scss">
.more--button {
  align-items: center;
  display: flex;
  margin-left: var(--space-small);
  padding: var(--space-small);
}

.actions--container {
  position: relative;
}

.dropdown-pane {
  right: 0;
  top: 48px;
  border: 1px solid var(--s-100);
  border-radius: var(--space-smaller);
  width: auto;
}

.dropdown-pane--open {
  display: block;
  visibility: visible;
}

.action--button {
  display: flex;
  align-items: center;
  width: 100%;
  padding: var(--space-small) 0;

  .icon {
    margin-right: var(--space-small);
    min-width: var(--space-normal);
  }
}
</style>
