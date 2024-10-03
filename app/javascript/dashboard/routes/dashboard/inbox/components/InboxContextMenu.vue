<script>
import ContextMenu from 'dashboard/components/ui/ContextMenu.vue';
import MenuItem from './MenuItem.vue';

export default {
  components: {
    MenuItem,
    ContextMenu,
  },
  props: {
    contextMenuPosition: {
      type: Object,
      default: () => ({}),
    },
    menuItems: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['close', 'selectAction'],
  methods: {
    handleClose() {
      this.$emit('close');
    },
    onMenuItemClick(key) {
      this.$emit('selectAction', key);
      this.handleClose();
    },
  },
};
</script>

<template>
  <ContextMenu
    :x="contextMenuPosition.x"
    :y="contextMenuPosition.y"
    @close="handleClose"
  >
    <div
      class="bg-white dark:bg-slate-900 w-40 py-1 border shadow-md border-slate-100 dark:border-slate-700/50 rounded-xl"
    >
      <MenuItem
        v-for="item in menuItems"
        :key="item.key"
        :label="item.label"
        @click.stop="onMenuItemClick(item.key)"
      />
    </div>
  </ContextMenu>
</template>
