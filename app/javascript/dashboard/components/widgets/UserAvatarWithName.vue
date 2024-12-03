<script setup>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

defineProps({
  user: {
    type: Object,
    default: () => ({}),
  },
  size: {
    type: String,
    default: '20px',
  },
  textClass: {
    type: String,
    default: 'text-sm text-n-slate-12',
  },
});
</script>

<template>
  <div class="flex items-center gap-1.5 text-left">
    <Thumbnail
      :src="user.thumbnail"
      :size="size"
      :username="user.name"
      :status="user.availability_status"
    />
    <span
      class="my-0 overflow-hidden whitespace-nowrap text-ellipsis text-capitalize"
      :class="textClass"
    >
      {{ user.name }}
    </span>
  </div>
</template>
