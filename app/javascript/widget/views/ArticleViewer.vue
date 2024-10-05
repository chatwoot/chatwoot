<script setup>
import IframeLoader from 'shared/components/IframeLoader.vue';

defineProps({
  link: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div class="bg-white h-full">
    <IframeLoader :url="link" />
  </div>
</template>
