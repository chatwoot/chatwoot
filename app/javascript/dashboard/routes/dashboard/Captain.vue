<script setup>
import { nextTick, onMounted, watch } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import IntegrationsAPI from 'dashboard/api/integrations';
import {
  makeRouter,
  setupApp,
} from '@chatwoot/captain-dashboard/dist/captain.es.js';

const props = defineProps({
  page: {
    type: String,
    required: true,
  },
});
const { accountId } = useAccount();

let app = null;
let router = null;

watch(
  () => props.page,
  () => {
    if (router) {
      router.push({ name: props.page });
    }
  },
  { immediate: true }
);

function buildApp() {
  router = makeRouter(`app/accounts/${accountId.value}/captain/`);
  app = setupApp('#captain', {
    router,
    fetchFn: async (source, options) => {
      const parsedSource = new URL(source);
      let path = parsedSource.pathname;
      if (path === `/api/sessions/profile`) {
        path = '/sessions/profile';
      } else {
        path = path.replace(/^\/api\/accounts\/\d+/, '');
      }

      // include search params
      path = `${path}${parsedSource.search}`;

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
  window.router = router;
  window.app = app;
}

onMounted(async () => {
  await nextTick();
  buildApp();
});
</script>

<template>
  <div id="captain" class="w-full" />
</template>

<style>
@import '@chatwoot/captain-dashboard/dist/style.css';
</style>
