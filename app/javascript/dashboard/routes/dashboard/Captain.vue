<script setup>
import { nextTick, onMounted } from 'vue';
import setupCaptain from '@chatwoot/captain-dashboard/dist/captain.es.js';

onMounted(async () => {
  await nextTick();
  setupCaptain(
    '#captain',
    'app/accounts/2/captain',
    'http://localhost:3000/api/v1/captin'
  );
});
</script>

<template>
  <div id="captain" class="w-full" />
</template>

<style>
@import '@chatwoot/captain-dashboard/dist/style.css';
</style>
