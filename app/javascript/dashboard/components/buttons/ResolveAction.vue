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
        </woot-dropdown-item>

        <woot-dropdown-divider v-if="isOpen" />
        <woot-dropdown-sub-menu
          v-if="isOpen"
          :title="this.$t('CONVERSATION.RESOLVE_DROPDOWN.SNOOZE.TITLE')"
        >
          <woot-dropdown-item>
            <woot-button
              variant="clear"
              color-scheme="secondary"
              size="small"
              icon="send-clock"
              @click="() => toggleStatus(STATUS_TYPE.SNOOZED, null)"
            >
              {{ this.$t('CONVERSATION.RESOLVE_DROPDOWN.SNOOZE.NEXT_REPLY') }}
            </woot-button>
          </woot-dropdown-item>
          <woot-dropdown-item>
            <woot-button
              variant="clear"
              color-scheme="secondary"
              size="small"
              icon="dual-screen-clock"
              @click="
                () => toggleStatus(STATUS_TYPE.SNOOZED, snoozeTimes.tomorrow)
              "
            >
              {{ this.$t('CONVERSATION.RESOLVE_DROPDOWN.SNOOZE.TOMORROW') }}
            </woot-button>
          </woot-dropdown-item>
          <woot-dropdown-item>
            <woot-button
              variant="clear"
              color-scheme="secondary"
              size="small"
              icon="calendar-clock"
              @click="
                () => toggleStatus(STATUS_TYPE.SNOOZED, snoozeTimes.nextWeek)
              "
            >
              {{ this.$t('CONVERSATION.RESOLVE_DROPDOWN.SNOOZE.NEXT_WEEK') }}
            </woot-button>
          </woot-dropdown-item>
        </woot-dropdown-sub-menu>
      </woot-dropdown-menu>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';
import alertMixin from 'shared/mixins/alertMixin';
import snoozeTimesMixin from 'dashboard/mixins/conversation/snoozeTimesMixin.js';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import {
  hasPressedAltAndEKey,
  hasPressedCommandPlusAltAndEKey,
  hasPressedAltAndMKey,
} from 'shared/helpers/KeyboardHelpers';

import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownSubMenu from 'shared/components/ui/dropdown/DropdownSubMenu.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import WootDropdownDivider from 'shared/components/ui/dropdown/DropdownDivider';

import wootConstants from '../../constants';
import {
  CMD_REOPEN_CONVERSATION,
  CMD_RESOLVE_CONVERSATION,
  CMD_SNOOZE_CONVERSATION,
} from '../../routes/dashboard/commands/commandBarBusEvents';

export default {
  components: {
    WootDropdownItem,
    WootDropdownMenu,
    WootDropdownSubMenu,
    WootDropdownDivider,
  },
  mixins: [clickaway, alertMixin, eventListenerMixins, snoozeTimesMixin],
  props: { conversationId: { type: [String, Number], required: true } },
  data() {
    return {
      isLoading: false,
      showActionsDropdown: false,
      STATUS_TYPE: wootConstants.STATUS_TYPE,
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
      this.toggleStatus(
        this.STATUS_TYPE.SNOOZED,
        this.snoozeTimes[snoozeType] || null
      );
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
}
</style>
