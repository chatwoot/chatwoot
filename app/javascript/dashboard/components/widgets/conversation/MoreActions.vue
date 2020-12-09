<template>
  <div class="flex-container actions--container">
    <resolve-action
      :conversation-id="currentChat.id"
      :status="currentChat.status"
    />
    <woot-button
      class="clear more--button"
      icon="ion-android-more-vertical"
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
        class="button small clear row alert small-6 action--button"
        @click="mute"
      >
        <span>{{ $t('CONTACT_PANEL.MUTE_CONTACT') }}</span>
      </button>

      <button
        v-else
        class="button small clear row alert small-6 action--button"
        @click="unmute"
      >
        <span>{{ $t('CONTACT_PANEL.UNMUTE_CONTACT') }}</span>
      </button>

      <button
        class="button small clear row small-6 action--button"
        @click="toggleEmailActionsModal"
      >
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
  },
  methods: {
    mute() {
      this.$store.dispatch('muteConversation', this.currentChat.id);
      this.showAlert(this.$t('CONTACT_PANEL.MUTED_SUCCESS'));
      this.toggleConversationActions();
    },
    unmute() {
      this.$store.dispatch('unmuteConversation', this.currentChat.id);
      this.showAlert(this.$t('CONTACT_PANEL.UNMUTED_SUCCESS'));
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
@import '~dashboard/assets/scss/mixins';

.more--button {
  align-items: center;
  display: flex;
  margin-left: var(--space-small);
  padding: var(--space-small);

  &.clear.more--button {
    color: var(--color-body);
  }

  &:hover {
    color: var(--w-800);
  }
}

.actions--container {
  position: relative;
}

.dropdown-pane {
  @include elegant-card;
  @include border-light;
  right: -12px;
  top: 48px;
  width: auto;

  &::before {
    @include arrow(top, var(--color-border-light), 14px);
    top: -14px;
    position: absolute;
    right: 6px;
  }

  &::after {
    @include arrow(top, white, var(--space-slab));
    top: -12px;
    position: absolute;
    right: var(--space-small);
  }
}

.dropdown-pane--open {
  display: block;
  visibility: visible;
}

.action--button {
  display: flex;
  align-items: center;
  width: 100%;
  white-space: nowrap;
  padding: var(--space-small) var(--space-smaller);
  font-size: var(--font-size-small);

  .icon {
    margin-right: var(--space-smaller);
    min-width: var(--space-normal);
  }
}
</style>
