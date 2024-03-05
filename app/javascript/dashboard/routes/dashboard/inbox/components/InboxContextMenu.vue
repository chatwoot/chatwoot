<template>
  <woot-context-menu
    :x="contextMenuPosition.x"
    :y="contextMenuPosition.y"
    @close="handleClose"
  >
    <div
      class="bg-white dark:bg-slate-900 w-40 py-1 border shadow-md border-slate-100 dark:border-slate-700/50 rounded-xl"
    >
      <menu-item
        v-for="item in menuItems"
        :key="item.key"
        :label="item.label"
        @click="onMenuItemClick(item.key)"
      />
    </div>
  </woot-context-menu>
</template>

<script>
import MenuItem from './MenuItem.vue';
export default {
  components: {
    MenuItem,
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
  methods: {
    handleClose() {
      this.$emit('close');
    },
    onMenuItemClick(key) {
      this.$emit('click', key);
      this.handleClose();
    },
  },
};
</script>
