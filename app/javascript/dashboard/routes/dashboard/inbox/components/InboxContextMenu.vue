<script setup>
import ContextMenu from 'dashboard/components/ui/ContextMenu.vue';
import MenuItem from 'dashboard/components/widgets/conversation/contextMenu/menuItem.vue';

defineProps({
  contextMenuPosition: {
    type: Object,
    default: () => ({}),
  },
  menuItems: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['close', 'selectAction']);

const handleClose = () => {
  emit('close');
};

const onMenuItemClick = key => {
  emit('selectAction', key);
  handleClose();
};
</script>

<template>
  <ContextMenu
    :x="contextMenuPosition.x"
    :y="contextMenuPosition.y"
    @close="handleClose"
  >
    <div
      class="p-1 rounded-md shadow-xl bg-s-subtle/50 backdrop-blur-[100px] outline-1 outline outline-s-border/50"
    >
      <MenuItem
        v-for="item in menuItems"
        :key="item.key"
        :option="item"
        variant="icon"
        class="!w-48"
        @click.stop="onMenuItemClick(item.key)"
      />
    </div>
  </ContextMenu>
</template>
