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
      class="bg-n-alpha-3 backdrop-blur-[100px] w-40 py-2 px-2 outline outline-1 outline-n-container shadow-lg rounded-xl"
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
