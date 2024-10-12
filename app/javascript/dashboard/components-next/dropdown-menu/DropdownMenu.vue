<script setup>
import { defineProps, defineEmits } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

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
    class="bg-white dark:bg-slate-800 absolute rounded-xl z-50 py-3 px-1 gap-2 flex flex-col min-w-[136px] shadow-lg"
  >
    <Button
      v-for="item in menuItems"
      :key="item.action"
      :label="item.label"
      :icon="item.icon"
      variant="ghost"
      size="sm"
      class="!justify-start w-full hover:bg-white dark:hover:bg-slate-800 z-60 font-normal"
      :text-variant="item.action === 'delete' ? 'danger' : ''"
      @click="handleAction(item.action)"
    />
  </div>
</template>
