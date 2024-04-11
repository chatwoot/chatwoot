<script setup>
import BaseEmptyState from './BaseEmptyState.vue';
import { getCurrentInstance } from 'vue';

// this is a hack to get the route and router from the parent component
// TODO: Move this to a separate util if we need to use this in multiple places
// https://github.com/vuejs/vue-router/issues/3760
const { proxy } = getCurrentInstance();
const route = proxy.$route;
const router = proxy.$router;

function routeToBilling() {
  const accountId = route.params.accountId;

  router.push({
    name: 'billing_settings_index',
    params: { accountId },
  });
}
</script>

<template>
  <base-empty-state>
    <div
      class="flex flex-col items-center max-w-md px-6 pt-6 pb-3 bg-white border shadow rounded-xl border-slate-100"
    >
      <div class="flex items-center w-full gap-2">
        <span
          class="flex items-center justify-center w-6 h-6 rounded-full bg-woot-100"
        >
          <fluent-icon size="14" class="text-woot-500" icon="lock-closed" />
        </span>
        <span class="text-base font-medium text-slate-900">
          Upgrade to create SLAs
        </span>
      </div>
      <p class="text-sm font-normal tracking-[0.5%] mt-4">
        SLA management is available on the
        <span class="font-medium text-slate-900">Business and Enterprise</span>
        plans only.
      </p>
      <p class="text-sm font-normal tracking-[0.5%]">
        Upgrade now to get access to advanced features like team management,
        automations, custom attributes, and more.
      </p>
      <woot-button
        color-scheme="primary"
        class="w-full mt-2 text-center rounded-xl"
        size="expanded"
        is-expanded
        @click="routeToBilling"
      >
        Upgrade Now
      </woot-button>
      <p class="mt-2 text-xs tracking-tighter text-center">
        You can change or cancel your plan anytime
      </p>
    </div>
  </base-empty-state>
</template>
