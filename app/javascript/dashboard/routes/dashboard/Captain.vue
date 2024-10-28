<script setup>
import { nextTick, onMounted } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import IntegrationsAPI from 'dashboard/api/integrations';

import setupCaptain from '@chatwoot/captain-dashboard/dist/captain.es.js';

const { accountId } = useAccount();

onMounted(async () => {
  await nextTick();
  setupCaptain('#captain', {
    routerBase: `app/accounts/${accountId.value}/captain/`,
    fetchFn: async (source, options) => {
      let path = new URL(source).pathname;
      if (path === `/api/sessions/profile`) {
        path = '/sessions/profile';
      } else {
        path = path.replace(/^\/api\/accounts\/\d+/, '');
      }

      const response = await IntegrationsAPI.requestCaptain({
        method: options.method ?? 'GET',
        route: path,
        body: options.body,
      });

      return {
        json: () => {
          return response.data;
        },
        ok: response.status === 200,
        status: response.status,
        headers: response.headers,
      };
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
