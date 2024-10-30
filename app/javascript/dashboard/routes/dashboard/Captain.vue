<script setup>
import { nextTick, onMounted, watch, computed } from 'vue';
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

const routeMap = {
  documents: '/app/accounts/[account_id]/documents/',
  playground: '/app/accounts/[account_id]/playground/',
  responses: '/app/accounts/[account_id]/responses/',
};

const resolvedRoute = computed(() => routeMap[props.page]);

let router = null;

watch(
  () => props.page,
  () => {
    if (router) {
      router.push({ name: resolvedRoute.value });
    }
  },
  { immediate: true }
);

function buildApp() {
  router = makeRouter();
  setupApp('#captain', {
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
        body: options.body ? JSON.parse(options.body) : null,
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

  router.push({ name: resolvedRoute.value });
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
