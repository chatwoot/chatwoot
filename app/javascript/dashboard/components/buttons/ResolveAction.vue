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
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';

import wootConstants from 'dashboard/constants/globals';
import {
  CMD_REOPEN_CONVERSATION,
  CMD_RESOLVE_CONVERSATION,
} from '../../routes/dashboard/commands/commandBarBusEvents';

export default {
  components: {
    WootDropdownItem,
    WootDropdownMenu,
  },
  mixins: [keyboardEventListenerMixins],
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
          useAlert(this.$t('CONVERSATION.CHANGE_STATUS'));
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
.dropdown-pane {
  @apply left-auto top-[2.625rem] mt-0.5 right-0 max-w-[12.5rem] min-w-[9.75rem];

  .dropdown-menu__item {
    @apply mb-0;
  }
}
</style>
