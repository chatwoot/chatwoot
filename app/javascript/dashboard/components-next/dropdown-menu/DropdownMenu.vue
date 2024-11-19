<script setup>
import { defineProps, defineEmits } from 'vue';

import Icon from 'dashboard/components-next/icon/Icon.vue';
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
    class="bg-n-alpha-3 backdrop-blur-[100px] border-0 outline outline-1 outline-n-container absolute rounded-xl z-50 py-2 px-2 gap-2 flex flex-col min-w-[136px] shadow-lg"
  >
    <button
      v-for="item in menuItems"
      :key="item.action"
      class="inline-flex items-center justify-start w-full h-8 min-w-0 gap-2 px-2 py-1.5 transition-all duration-200 ease-in-out border-0 rounded-lg z-60 hover:bg-n-alpha-1 dark:hover:bg-n-alpha-2 disabled:cursor-not-allowed disabled:pointer-events-none disabled:opacity-50"
      :class="{
        'bg-n-alpha-1 dark:bg-n-solid-active': item.isSelected,
        'text-n-ruby-11': item.action === 'delete',
        'text-n-slate-12': item.action !== 'delete',
      }"
      :disabled="item.disabled"
      @click="handleAction(item.action, item.value)"
    >
      <Thumbnail
        v-if="item.thumbnail"
        :author="item.thumbnail"
        :name="item.thumbnail.name"
        :size="thumbnailSize"
        :src="item.thumbnail.src"
      />
      <Icon v-if="item.icon" :icon="item.icon" class="flex-shrink-0" />
      <span v-if="item.emoji" class="flex-shrink-0">{{ item.emoji }}</span>
      <span v-if="item.label" class="min-w-0 text-sm truncate">{{
        item.label
      }}</span>
    </button>
  </div>
</template>
