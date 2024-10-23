<script setup>
import { nextTick, onMounted } from 'vue';
import setupCaptain from '@chatwoot/captain-dashboard';

onMounted(async () => {
  await nextTick();
  setupCaptain('#captain');
});
</script>

<template>
  <div id="captain" />
</template>
