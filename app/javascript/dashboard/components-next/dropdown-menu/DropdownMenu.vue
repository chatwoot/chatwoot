<script setup>
import { defineProps, defineEmits } from 'vue';

import Button from 'dashboard/components-next/button/Button.vue';
import Thumbnail from 'dashboard/components-next/thumbnail/Thumbnail.vue';

defineProps({
  menuItems: {
    type: Array,
    required: true,
    validator: value => {
      return value.every(item => item.action && item.value && item.label);
    },
  },
  thumbnailSize: {
    type: Number,
    default: 20,
  },
});

const emit = defineEmits(['action']);

const handleAction = (action, value) => {
  emit('action', { action, value });
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
      :emoji="item.emoji"
      :disabled="item.disabled"
      variant="ghost"
      size="sm"
      class="!justify-start w-full hover:bg-white dark:hover:bg-slate-800 z-60 text-slate-800 dark:text-slate-100 font-normal"
      :class="item.isSelected ? '!bg-slate-50 dark:!bg-slate-700/50' : ''"
      :text-variant="item.action === 'delete' ? 'danger' : ''"
      @click="handleAction(item.action, item.value)"
    >
      <template #leftPrefix>
        <Thumbnail
          v-if="item.thumbnail"
          :author="item.thumbnail"
          :name="item.thumbnail.name"
          :size="thumbnailSize"
          :src="item.thumbnail.src"
        />
      </template>
    </Button>
  </div>
</template>
