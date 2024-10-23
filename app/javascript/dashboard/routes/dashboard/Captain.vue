<script setup>
import { nextTick, onMounted } from 'vue';
import setupCaptain from '@chatwoot/captain-dashboard/dist/captain.es.js';

onMounted(async () => {
  await nextTick();
  setupCaptain('#captain', 'app/accounts/2/captain');
});
</script>

<template>
  <div id="captain" class="w-full" />
</template>
