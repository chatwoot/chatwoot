<script setup>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

defineProps({
  user: {
    type: Object,
    default: () => {},
  },
  size: {
    type: String,
    default: '20px',
  },
  textClass: {
    type: String,
    default: 'text-xs text-slate-600',
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
    <h6
      class="my-0 dark:text-slate-100 overflow-hidden whitespace-nowrap text-ellipsis text-capitalize"
      :class="textClass"
    >
      {{ user.name }}
    </h6>
  </div>
</template>
