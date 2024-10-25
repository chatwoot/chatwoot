<script setup>
import { nextTick, onMounted } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import IntegrationsAPI from 'dashboard/api/integrations';

import setupCaptain from '@chatwoot/captain-dashboard/dist/captain.es.js';

const { accountId, currentAccount } = useAccount();

onMounted(async () => {
  await nextTick();
  setupCaptain('#captain', {
    routerBase: `app/accounts/${accountId.value}/captain`,
    fetchFn: async (source, options) => {
      const path = new URL(source).pathname;
      if (path === `/api/sessions/profile`) {
        // need to proxy the request
        return Promise.resolve({
          account: {
            id: accountId.value,
            name: currentAccount.value.name,
          },
        });
      }

      const parsedPath = path.replace(/^\/api\/accounts\/\d+/, '');
      return IntegrationsAPI.requestCaptain({
        method: options.method ?? 'GET',
        route: parsedPath,
        body: options.body,
      });
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
