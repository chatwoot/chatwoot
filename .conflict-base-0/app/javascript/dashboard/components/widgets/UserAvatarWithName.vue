<script setup>
import Avatar from 'next/avatar/Avatar.vue';

defineProps({
  user: {
    type: Object,
    default: () => ({}),
  },
  size: {
    type: Number,
    default: 20,
  },
  textClass: {
    type: String,
    default: 'text-sm text-n-slate-12',
  },
});
</script>

<template>
  <div class="flex items-center gap-1.5 text-left">
    <Avatar
      :src="user.thumbnail"
      :size="size"
      :name="user.name"
      :status="user.availability_status"
      hide-offline-status
      rounded-full
    />
    <span class="my-0 truncate text-capitalize" :class="textClass">
      {{ user.name }}
    </span>
  </div>
</template>
