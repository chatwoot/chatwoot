<script setup>
import Banner from 'dashboard/components-next/banner/Banner.vue';

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
      <div class="flex"><fluent-icon icon="info" size="16" /></div>
      {{ content }}
    </div>
  </Banner>
</template>
