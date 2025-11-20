<template>
  <div class="relative flex items-center justify-end resolve-actions">
    <div class="button-group">
      <woot-button
        v-if="isOpen"
        class-names="resolve"
        color-scheme="success"
        icon="checkmark"
        emoji="✅"
        :is-loading="isLoading"
        @click="onCmdResolveConversation"
      >
        {{ $t('CONVERSATION.HEADER.RESOLVE_ACTION') }}
      </woot-button>
      <woot-button
        v-else-if="isResolved"
        class-names="resolve"
        color-scheme="warning"
        icon="arrow-redo"
        emoji="👀"
        :is-loading="isLoading"
        @click="onCmdOpenConversation"
      >
        {{ $t('CONVERSATION.HEADER.REOPEN_ACTION') }}
      </woot-button>
      <woot-button
        v-else-if="showOpenButton"
        class-names="resolve"
        color-scheme="primary"
        icon="person"
        :is-loading="isLoading"
        @click="onCmdOpenConversation"
      >
        {{ $t('CONVERSATION.HEADER.OPEN_ACTION') }}
      </woot-button>
      <woot-button
        v-if="showAdditionalActions"
        ref="arrowDownButton"
        :color-scheme="buttonClass"
        :disabled="isLoading"
        icon="chevron-down"
        emoji="🔽"
        @click="openDropdown"
      />
    </div>
    <div
      v-if="showActionsDropdown"
      v-on-clickaway="closeDropdown"
      class="dropdown-pane dropdown-pane--open"
    >
      <woot-dropdown-menu class="mb-0">
        <woot-dropdown-item v-if="!isPending">
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="snooze"
            @click="() => openSnoozeModal()"
          >
            {{ $t('CONVERSATION.RESOLVE_DROPDOWN.SNOOZE_UNTIL') }}
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item v-if="!isPending">
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="book-clock"
            @click="() => toggleStatus(STATUS_TYPE.PENDING)"
          >
            {{ $t('CONVERSATION.RESOLVE_DROPDOWN.MARK_PENDING') }}
          </woot-button>
        </woot-dropdown-item>
      </woot-dropdown-menu>
    </div>
    <conversation-label-modal
      v-if="showResolveConversationModal && !isLabelsAdded"
      :show="showResolveConversationModal"
      :current-chat="currentChat"
      @submit="markConversationResolved"
      @cancel="toggleResolveConversationModal"
    />
    <custom-attributes-form
      v-if="showCustomAttributesForm"
      :show="showCustomAttributesForm"
      @submit="markConversationResolved"
      @cancel="toggleCustomAttributesForm"
    />
    <csat-prompt-modal
      v-if="showCsatPromptModal"
      :show="showCsatPromptModal"
      @send-csat="onSendCsat"
      @skip-csat="onSkipCsat"
      @cancel="toggleCsatPromptModal"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import ConversationLabelModal from '../widgets/conversation/ConversationLabelModal.vue';
import CustomAttributesForm from '../widgets/conversation/CustomAttributesForm.vue';
import CsatPromptModal from '../widgets/conversation/CsatPromptModal.vue';

import wootConstants from 'dashboard/constants/globals';
import {
  CMD_REOPEN_CONVERSATION,
  CMD_RESOLVE_CONVERSATION,
} from '../../routes/dashboard/commands/commandBarBusEvents';
import attributeMixin from '../../mixins/attributeMixin';

export default {
  components: {
    WootDropdownItem,
    WootDropdownMenu,
    ConversationLabelModal,
    CustomAttributesForm,
    CsatPromptModal,
  },
  mixins: [alertMixin, keyboardEventListenerMixins, attributeMixin],
  props: {
    conversationId: { type: [String, Number], required: true },
    inboxId: { type: [String, Number], required: true },
    isLabelsAdded: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      isLoading: false,
      showActionsDropdown: false,
      STATUS_TYPE: wootConstants.STATUS_TYPE,
      showResolveConversationModal: false,
      showCustomAttributesForm: false,
      showCsatPromptModal: false,
      attributeType: 'conversation_attribute',
      shouldSendCsat: false,
    };
  },
  computed: {
    ...mapGetters({ currentChat: 'getSelectedChat' }),
    isOpen() {
      return this.currentChat.status === wootConstants.STATUS_TYPE.OPEN;
    },
    isPending() {
      return this.currentChat.status === wootConstants.STATUS_TYPE.PENDING;
    },
    isResolved() {
      return this.currentChat.status === wootConstants.STATUS_TYPE.RESOLVED;
    },
    isSnoozed() {
      return this.currentChat.status === wootConstants.STATUS_TYPE.SNOOZED;
    },
    buttonClass() {
      if (this.isPending) return 'primary';
      if (this.isOpen) return 'success';
      if (this.isResolved) return 'warning';
      return '';
    },
    showAdditionalActions() {
      return !this.isPending && !this.isSnoozed;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.inboxId) || {};
    },
    isShowCustomAttributesForm() {
      return this.attributes.some(
        attribute => attribute.required_before_resolve
      );
    },
    shouldShowCsatPrompt() {
      // Check if inbox has CSAT enabled and agent prompt enabled
      if (
        !this.inbox.csat_survey_enabled ||
        !this.inbox.prompt_agent_for_csat
      ) {
        return false;
      }

      // Check if conversation is being resolved from open state
      if (!this.isOpen) {
        return false;
      }

      // Get CSAT messages from the conversation
      const csatMessages =
        this.currentChat.messages?.filter(
          msg =>
            msg.content_type === 'input_csat' &&
            !msg.additional_attributes?.ignore_automation_rules
        ) || [];

      // If no previous CSAT, show prompt
      if (csatMessages.length === 0) {
        return true;
      }

      // If inbox doesn't allow resend after expiry, don't show prompt
      if (!this.inbox.csat_allow_resend_after_expiry) {
        return false;
      }

      // Check if the latest CSAT message is expired
      const latestCsat = csatMessages.sort(
        (a, b) => new Date(b.created_at) - new Date(a.created_at)
      )[0];

      return this.isCsatExpired(latestCsat);
    },
  },
  mounted() {
    this.$emitter.on(CMD_REOPEN_CONVERSATION, this.onCmdOpenConversation);
    this.$emitter.on(CMD_RESOLVE_CONVERSATION, this.onCmdResolveConversation);
  },
  destroyed() {
    this.$emitter.off(CMD_REOPEN_CONVERSATION, this.onCmdOpenConversation);
    this.$emitter.off(CMD_RESOLVE_CONVERSATION, this.onCmdResolveConversation);
  },
  methods: {
    getKeyboardEvents() {
      return {
        'Alt+KeyM': {
          action: () => this.$refs.arrowDownButton?.$el.click(),
          allowOnFocusedInput: true,
        },
        'Alt+KeyE': this.resolveOrToast,
        '$mod+Alt+KeyE': async event => {
          const { all, activeIndex, lastIndex } = this.getConversationParams();
          await this.resolveOrToast();

          if (activeIndex < lastIndex) {
            all[activeIndex + 1].click();
          } else if (all.length > 1) {
            all[0].click();
            document.querySelector('.conversations-list').scrollTop = 0;
          }

          event.preventDefault();
        },
      };
    },
    getConversationParams() {
      const allConversations = document.querySelectorAll(
        '.conversations-list .conversation'
      );

      const activeConversation = document.querySelector(
        'div.conversations-list div.conversation.active'
      );
      const activeConversationIndex = [...allConversations].indexOf(
        activeConversation
      );
      const lastConversationIndex = allConversations.length - 1;

      return {
        all: allConversations,
        activeIndex: activeConversationIndex,
        lastIndex: lastConversationIndex,
      };
    },
    async resolveOrToast() {
      try {
        await this.toggleStatus(wootConstants.STATUS_TYPE.RESOLVED);
      } catch (error) {
        // error
      }
    },
    onCmdOpenConversation() {
      this.toggleStatus(this.STATUS_TYPE.OPEN);
    },
    onCmdResolveConversation() {
      if (this.isShowCustomAttributesForm) {
        this.toggleCustomAttributesForm();
        return;
      }
      if (this.inbox.add_label_to_resolve_conversation && !this.isLabelsAdded) {
        this.toggleResolveConversationModal();
      } else {
        this.markConversationResolved();
      }
    },
    markConversationResolved() {
      // Check if we should prompt for CSAT based on expiry logic
      if (this.shouldShowCsatPrompt) {
        this.toggleCsatPromptModal();
      } else {
        this.toggleStatus(this.STATUS_TYPE.RESOLVED);
      }
    },
    showOpenButton() {
      return this.isResolved || this.isSnoozed;
    },
    closeDropdown() {
      this.showActionsDropdown = false;
    },
    openDropdown() {
      this.showActionsDropdown = true;
    },
    toggleStatus(status, snoozedUntil, skipCsat = false) {
      this.closeDropdown();
      this.isLoading = true;
      this.$store
        .dispatch('toggleStatus', {
          conversationId: this.currentChat.id,
          status,
          snoozedUntil,
          skipCsat,
        })
        .then(() => {
          this.showAlert(this.$t('CONVERSATION.CHANGE_STATUS'));
          this.isLoading = false;
        });
    },
    openSnoozeModal() {
      const ninja = document.querySelector('ninja-keys');
      ninja.open({ parent: 'snooze_conversation' });
    },
    toggleResolveConversationModal() {
      this.showResolveConversationModal = !this.showResolveConversationModal;
    },
    toggleCustomAttributesForm() {
      this.showCustomAttributesForm = !this.showCustomAttributesForm;
    },
    toggleCsatPromptModal() {
      this.showCsatPromptModal = !this.showCsatPromptModal;
    },
    onSendCsat() {
      this.shouldSendCsat = true;
      this.toggleCsatPromptModal();
      this.toggleStatus(this.STATUS_TYPE.RESOLVED);
    },
    onSkipCsat() {
      this.shouldSendCsat = false;
      this.toggleCsatPromptModal();
      this.toggleStatus(this.STATUS_TYPE.RESOLVED, null, true);
    },
    isCsatExpired(csatMessage) {
      if (!csatMessage || !this.inbox.csat_allow_resend_after_expiry) {
        return false;
      }

      if (!this.inbox.csat_expiry_hours) {
        return false;
      }

      const expiryHours = this.inbox.csat_expiry_hours;
      const expiryMilliseconds = expiryHours * 60 * 60 * 1000;

      // Handle both Unix timestamp (seconds) and ISO date string
      let messageTime;
      if (typeof csatMessage.created_at === 'number') {
        // Unix timestamp in seconds - convert to milliseconds
        messageTime = csatMessage.created_at * 1000;
      } else {
        // ISO date string or Date object
        messageTime = new Date(csatMessage.created_at).getTime();
      }

      const currentTime = new Date().getTime();

      return currentTime - messageTime > expiryMilliseconds;
    },
  },
};
</script>
<style lang="scss" scoped>
.dropdown-pane {
  @apply left-auto top-[2.625rem] mt-0.5 right-0 max-w-[12.5rem] min-w-[9.75rem];

  .dropdown-menu__item {
    @apply mb-0;
  }
}
</style>
