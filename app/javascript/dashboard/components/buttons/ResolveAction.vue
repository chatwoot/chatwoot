<template>
  <div class="resolve-actions">
    <div class="button-group">
      <woot-button
        v-if="isOpen"
        class-names="resolve"
        color-scheme="success"
        icon="ion-checkmark"
        emoji="✅"
        :is-loading="isLoading"
        @click="() => toggleStatus(STATUS_TYPE.RESOLVED)"
      >
        {{ this.$t('CONVERSATION.HEADER.RESOLVE_ACTION') }}
      </woot-button>
      <woot-button
        v-else-if="isResolved"
        class-names="resolve"
        color-scheme="warning"
        icon="ion-refresh"
        emoji="👀"
        :is-loading="isLoading"
        @click="() => toggleStatus(STATUS_TYPE.OPEN)"
      >
        {{ this.$t('CONVERSATION.HEADER.REOPEN_ACTION') }}
      </woot-button>
      <woot-button
        v-else-if="isPending"
        class-names="resolve"
        color-scheme="primary"
        icon="ion-person"
        :is-loading="isLoading"
        @click="() => toggleStatus(STATUS_TYPE.OPEN)"
      >
        {{ this.$t('CONVERSATION.HEADER.OPEN_ACTION') }}
      </woot-button>
      <woot-button
        v-if="showDropDown"
        :color-scheme="buttonClass"
        :disabled="isLoading"
        icon="ion-arrow-down-b"
        emoji="🔽"
        @click="openDropdown"
      />
    </div>
    <div
      v-if="showDropdown"
      v-on-clickaway="closeDropdown"
      class="dropdown-pane dropdown-pane--open"
    >
      <woot-dropdown-menu>
        <woot-dropdown-item v-if="!isPending">
          <woot-button
            variant="clear"
            @click="() => toggleStatus(STATUS_TYPE.PENDING)"
          >
            {{ this.$t('CONVERSATION.RESOLVE_DROPDOWN.MARK_PENDING') }}
          </woot-button>
        </woot-dropdown-item>
      </woot-dropdown-menu>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';
import alertMixin from 'shared/mixins/alertMixin';

import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import wootConstants from '../../constants';

export default {
  components: {
    WootDropdownItem,
    WootDropdownMenu,
  },
  mixins: [clickaway, alertMixin],
  props: { conversationId: { type: [String, Number], required: true } },
  data() {
    return {
      isLoading: false,
      showDropdown: false,
      STATUS_TYPE: wootConstants.STATUS_TYPE,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    isOpen() {
      return this.currentChat.status === wootConstants.STATUS_TYPE.OPEN;
    },
    isPending() {
      return this.currentChat.status === wootConstants.STATUS_TYPE.PENDING;
    },
    isResolved() {
      return this.currentChat.status === wootConstants.STATUS_TYPE.RESOLVED;
    },
    buttonClass() {
      if (this.isPending) return 'primary';
      if (this.isOpen) return 'success';
      if (this.isResolved) return 'warning';
      return '';
    },
    showDropDown() {
      return !this.isPending;
    },
  },
  methods: {
    closeDropdown() {
      this.showDropdown = false;
    },
    openDropdown() {
      this.showDropdown = true;
    },
    toggleStatus(status) {
      this.closeDropdown();
      this.isLoading = true;
      this.$store
        .dispatch('toggleStatus', {
          conversationId: this.currentChat.id,
          status,
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
}
</style>
