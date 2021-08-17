<template>
  <div class="context-menu">
    <woot-button
      icon="ion-more"
      size="large"
      class="button--delete-message"
      color-scheme="secondary"
      variant="link"
      @click="handleContextMenuClick"
    />
    <div
      v-if="isOpen"
      v-on-clickaway="handleContextMenuClick"
      class="dropdown-pane dropdown-pane--open"
      :class="`dropdown-pane--${menuPosition}`"
    >
      <woot-dropdown-menu>
        <woot-dropdown-item v-if="showCopy">
          <woot-button
            variant="clear"
            size="small"
            icon="ion-ios-copy-outline"
            @click="handleCopy"
          >
            {{ $t('CONVERSATION.CONTEXT_MENU.COPY') }}
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            color-scheme="alert"
            size="small"
            icon="ion-trash-a"
            @click="handleDelete"
          >
            {{ $t('CONVERSATION.CONTEXT_MENU.DELETE') }}
          </woot-button>
        </woot-dropdown-item>
      </woot-dropdown-menu>
    </div>
  </div>
</template>
<script>
import { mixin as clickaway } from 'vue-clickaway';

import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu';

export default {
  components: {
    WootDropdownMenu,
    WootDropdownItem,
  },
  mixins: [clickaway],
  props: {
    isOpen: {
      type: Boolean,
      default: false,
    },
    showCopy: {
      type: Boolean,
      default: false,
    },
    menuPosition: {
      type: String,
      default: 'left',
    },
  },
  methods: {
    handleContextMenuClick() {
      this.$emit('toggle', !this.isOpen);
    },
    handleCopy() {
      this.$emit('copy');
    },
    handleDelete() {
      this.$emit('delete');
    },
  },
};
</script>
<style lang="scss" scoped>
/* TDOD: Remove once MenuComponent supports postions */
.dropdown-pane {
  bottom: var(--space-medium);
}
.dropdown-pane--left {
  right: var(--space-small);
}
.dropdown-pane--right {
  left: var(--space-small);
}
</style>
