<script setup>
import Banner from 'dashboard/components-next/banner/Banner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  content: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <Banner color="amber">
    <div class="flex items-center gap-2">
      <Icon icon="i-lucide-info" class="size-4" />
      <span>{{ content }}</span>
    </div>
  </Banner>
</template>
