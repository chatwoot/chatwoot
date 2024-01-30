<script setup>
import { defineProps, defineEmits } from 'vue';
import MenuItem from './MenuItem.vue';

defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
  contextMenuPosition: {
    type: Object,
    default: () => ({}),
  },
});

const menuItems = [
  {
    key: 'mark_as_read',
    label: 'Mark as read',
  },
  {
    key: 'mark_as_unread',
    label: 'Mark as unread',
  },
  {
    key: 'snooze',
    label: 'Snooze',
  },
  {
    key: 'delete',
    label: 'Delete',
  },
];

const emits = defineEmits(['close']);

const handleClose = () => {
  emits('close');
};

const onMenuItemClick = () => {
  // handle menu item click
};
</script>
<template>
  <woot-context-menu
    v-if="isOpen"
    :x="contextMenuPosition.x"
    :y="contextMenuPosition.y"
    @close="handleClose"
  >
    <div
      class="bg-white dark:bg-slate-900 w-40 py-1 border shadow-md border-slate-100 dark:border-slate-500 rounded-xl"
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
