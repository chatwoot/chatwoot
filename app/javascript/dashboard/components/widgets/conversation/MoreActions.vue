<template>
  <div class="flex-container actions--container">
    <resolve-action
      :conversation-id="currentChat.id"
      :status="currentChat.status"
    />
    <woot-button
      class="more--button"
      variant="clear"
      size="large"
      color-scheme="secondary"
      icon="ion-android-more-vertical"
      @click="toggleConversationActions"
    />
    <div
      v-if="showConversationActions"
      v-on-clickaway="hideConversationActions"
      class="dropdown-pane dropdowm--bottom"
      :class="{ 'dropdown-pane--open': showConversationActions }"
    >
      <woot-dropdown-menu>
        <woot-dropdown-item v-if="!currentChat.muted">
          <button class="button clear alert " @click="mute">
            <span>{{ $t('CONTACT_PANEL.MUTE_CONTACT') }}</span>
          </button>
        </woot-dropdown-item>
        <woot-dropdown-item v-else>
          <button class="button clear alert" @click="unmute">
            <span>{{ $t('CONTACT_PANEL.UNMUTE_CONTACT') }}</span>
          </button>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <button class="button clear" @click="toggleEmailActionsModal">
            {{ $t('CONTACT_PANEL.SEND_TRANSCRIPT') }}
          </button>
        </woot-dropdown-item>
      </woot-dropdown-menu>
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
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';

export default {
  components: {
    WootDropdownMenu,
    WootDropdownItem,
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
