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
  <Banner color="ruby">
    {{ content }}
  </Banner>
</template>
