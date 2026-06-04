<script setup>
import { nextTick, watch, computed } from 'vue';
import IntegrationsAPI from 'dashboard/api/integrations';
import { useStoreGetters } from 'dashboard/composables/store';
import { makeRouter, setupApp } from '@chatwoot/captain';

const props = defineProps({
  page: {
    type: String,
    required: true,
  },
});

const getters = useStoreGetters();

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

const buildApp = () => {
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
        ok: response.status >= 200 && response.status < 300,
        status: response.status,
        headers: response.headers,
      };
    },
  });

  router.push({ name: resolvedRoute.value });
};

const captainIntegration = computed(() =>
  getters['integrations/getIntegration'].value('captain', null)
);

watch(
  () => captainIntegration.value,
  (newValue, prevValue) => {
    if (!prevValue && newValue) {
      nextTick(() => buildApp());
    }
  },
  { immediate: true }
);
</script>

<template>
  <div v-if="!captainIntegration">
    {{ $t('INTEGRATION_SETTINGS.CAPTAIN.DISABLED') }}
  </div>
  <div
    v-else-if="!captainIntegration.enabled"
    class="flex-1 flex flex-col gap-2 items-center justify-center"
  >
    <div>{{ $t('INTEGRATION_SETTINGS.CAPTAIN.DISABLED') }}</div>
    <router-link :to="{ name: 'settings_applications' }">
      <woot-button class="clear link">
        {{ $t('INTEGRATION_SETTINGS.CAPTAIN.CLICK_HERE_TO_CONFIGURE') }}
      </woot-button>
    </router-link>
  </div>
  <div v-else id="captain" class="w-full" />
</template>

<style>
@import '@chatwoot/captain/dist/style.css';
</style>
