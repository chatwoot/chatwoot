<template>
  <div class="resolve-actions">
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
        {{ this.$t('CONVERSATION.HEADER.RESOLVE_ACTION') }}
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
        {{ this.$t('CONVERSATION.HEADER.REOPEN_ACTION') }}
      </woot-button>
      <woot-button
        v-else-if="showOpenButton"
        class-names="resolve"
        color-scheme="primary"
        icon="person"
        :is-loading="isLoading"
        @click="onCmdOpenConversation"
      >
        {{ this.$t('CONVERSATION.HEADER.OPEN_ACTION') }}
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
      <woot-dropdown-menu>
        <woot-dropdown-item v-if="!isPending">
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="book-clock"
            @click="() => toggleStatus(STATUS_TYPE.PENDING)"
          >
            {{ this.$t('CONVERSATION.RESOLVE_DROPDOWN.MARK_PENDING') }}
          </woot-button>
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="snooze"
            @click="() => openSnoozeModal()"
          >
            {{ this.$t('CONVERSATION.RESOLVE_DROPDOWN.SNOOZE_UNTIL') }}
          </woot-button>
        </woot-dropdown-item>
      </woot-dropdown-menu>
    </div>
    <woot-modal
      :show.sync="showCustomSnoozeModal"
      :on-close="hideCustomSnoozeModal"
    >
      <CustomSnoozeModal
        @on-close="hideCustomSnoozeModal"
        @choose-time="chooseSnoozeTime"
      />
    </woot-modal>
  </div>
</template>

<script>
import { getUnixTime } from 'date-fns';
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';
import alertMixin from 'shared/mixins/alertMixin';
import CustomSnoozeModal from 'dashboard/components/CustomSnoozeModal';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import {
  hasPressedAltAndEKey,
  hasPressedCommandPlusAltAndEKey,
  hasPressedAltAndMKey,
} from 'shared/helpers/KeyboardHelpers';
import { findSnoozeTime } from 'dashboard/helper/snoozeHelpers';
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';

import wootConstants from 'dashboard/constants/globals';
import {
  CMD_REOPEN_CONVERSATION,
  CMD_RESOLVE_CONVERSATION,
  CMD_SNOOZE_CONVERSATION,
} from '../../routes/dashboard/commands/commandBarBusEvents';

export default {
  components: {
    WootDropdownItem,
    WootDropdownMenu,
    CustomSnoozeModal,
  },
  mixins: [clickaway, alertMixin, eventListenerMixins],
  props: { conversationId: { type: [String, Number], required: true } },
  data() {
    return {
      isLoading: false,
      showActionsDropdown: false,
      STATUS_TYPE: wootConstants.STATUS_TYPE,
      showCustomSnoozeModal: false,
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
  },
  mounted() {
    bus.$on(CMD_SNOOZE_CONVERSATION, this.onCmdSnoozeConversation);
    bus.$on(CMD_REOPEN_CONVERSATION, this.onCmdOpenConversation);
    bus.$on(CMD_RESOLVE_CONVERSATION, this.onCmdResolveConversation);
  },
  destroyed() {
    bus.$off(CMD_SNOOZE_CONVERSATION, this.onCmdSnoozeConversation);
    bus.$off(CMD_REOPEN_CONVERSATION, this.onCmdOpenConversation);
    bus.$off(CMD_RESOLVE_CONVERSATION, this.onCmdResolveConversation);
  },
  methods: {
    async handleKeyEvents(e) {
      const allConversations = document.querySelectorAll(
        '.conversations-list .conversation'
      );
      if (hasPressedAltAndMKey(e)) {
        if (this.$refs.arrowDownButton) {
          this.$refs.arrowDownButton.$el.click();
        }
      }
      if (hasPressedAltAndEKey(e)) {
        const activeConversation = document.querySelector(
          'div.conversations-list div.conversation.active'
        );
        const activeConversationIndex = [...allConversations].indexOf(
          activeConversation
        );
        const lastConversationIndex = allConversations.length - 1;
        try {
          await this.toggleStatus(wootConstants.STATUS_TYPE.RESOLVED);
        } catch (error) {
          // error
        }
        if (hasPressedCommandPlusAltAndEKey(e)) {
          if (activeConversationIndex < lastConversationIndex) {
            allConversations[activeConversationIndex + 1].click();
          } else if (allConversations.length > 1) {
            allConversations[0].click();
            document.querySelector('.conversations-list').scrollTop = 0;
          }
          e.preventDefault();
        }
      }
    },
    onCmdSnoozeConversation(snoozeType) {
      if (snoozeType === wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME) {
        this.showCustomSnoozeModal = true;
      } else {
        this.toggleStatus(
          this.STATUS_TYPE.SNOOZED,
          findSnoozeTime(snoozeType) || null
        );
      }
    },
    chooseSnoozeTime(customSnoozeTime) {
      this.showCustomSnoozeModal = false;
      this.toggleStatus(
        this.STATUS_TYPE.SNOOZED,
        getUnixTime(customSnoozeTime)
      );
    },
    hideCustomSnoozeModal() {
      this.showCustomSnoozeModal = false;
    },
    onCmdOpenConversation() {
      this.toggleStatus(this.STATUS_TYPE.OPEN);
    },
    onCmdResolveConversation() {
      this.toggleStatus(this.STATUS_TYPE.RESOLVED);
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
    toggleStatus(status, snoozedUntil) {
      this.closeDropdown();
      this.isLoading = true;
      this.$store
        .dispatch('toggleStatus', {
          conversationId: this.currentChat.id,
          status,
          snoozedUntil,
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
  },
};
</script>
<style lang="scss" scoped>
.resolve-actions {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: flex-end;
}

.dropdown-pane {
  left: unset;
  top: 4.2rem;
  margin-top: var(--space-micro);
  right: 0;
  max-width: 20rem;
  min-width: 15.6rem;

  .dropdown-menu__item {
    margin-bottom: var(--space-zero);
  }
}
</style>
