<script setup>
import { nextTick, onMounted } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import setupCaptain from '@chatwoot/captain-dashboard/dist/captain.es.js';

const { accountId } = useAccount();

onMounted(async () => {
  await nextTick();
  setupCaptain('#captain', {
    routerBase: `app/accounts/${accountId}/captain`,
    fetchFn: async (source, options) => {
      console.log(source, options);
      return fetch(source, options);
    },
  });
});
</script>

<template>
  <div id="captain" class="w-full" />
</template>

<style>
@import '@chatwoot/captain-dashboard/dist/style.css';
</style>
