<script setup>
import BaseEmptyState from './BaseEmptyState.vue';

defineProps({
  isAdmin: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <base-empty-state>
    <div
      class="flex flex-col items-center max-w-md px-6 py-6 bg-white border shadow rounded-xl border-slate-100"
    >
      <div class="flex items-center w-full gap-2">
        <span
          class="flex items-center justify-center w-6 h-6 rounded-full bg-woot-100"
        >
          <fluent-icon size="14" class="text-woot-500" icon="lock-closed" />
        </span>
        <span class="text-base font-medium text-slate-900">
          {{ $t('SLA.PAYWALL.TITLE') }}
        </span>
      </div>
      <p
        class="text-sm font-normal tracking-[0.5%] mt-4"
        v-html="$t('SLA.ENTERPRISE_PAYWALL.AVAILABLE_ON')"
      />
      <template v-if="isAdmin">
        <p class="text-sm font-normal tracking-[0.5%]">
          {{ $t('SLA.PAYWALL.UPGRADE_PROMPT') }}
        </p>
        <a href="/super_admin" class="block w-full">
          <woot-button
            color-scheme="primary"
            class="w-full mt-2 text-center rounded-xl"
            size="expanded"
            is-expanded
          >
            {{ $t('SLA.PAYWALL.UPGRADE_NOW') }}
          </woot-button>
        </a>
      </template>
      <template v-else>
        <p class="text-sm font-normal tracking-[0.5%]">
          {{ $t('SLA.PAYWALL.ASK_ADMIN') }}
        </p>
      </template>
    </div>
  </base-empty-state>
</template>
