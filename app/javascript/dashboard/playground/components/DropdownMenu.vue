<script setup>
import { defineProps, defineEmits } from 'vue';
import ButtonV4 from './Button.vue';

defineProps({
  menuItems: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['action']);

const handleAction = action => {
  emit('action', action);
};
</script>

<template>
  <div
    class="bg-white dark:bg-gray-800 absolute rounded-xl py-3 px-1 min-w-[136px] shadow-lg"
  >
    <ButtonV4
      v-for="item in menuItems"
      :key="item.action"
      :label="item.label"
      :icon="item.icon"
      variant="ghost"
      size="sm"
      :text-variant="item.action === 'delete' ? 'danger' : ''"
      @click="handleAction(item.action)"
    />
  </div>
</template>
