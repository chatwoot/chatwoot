<script setup>
defineProps({
  featurePrefix: {
    type: String,
    required: true,
  },
  i18nKey: {
    type: String,
    required: true,
  },
  isOnChatwootCloud: {
    type: Boolean,
    default: false,
  },
  isSuperAdmin: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['upgrade']);
</script>

<template>
  <div
    class="flex flex-col max-w-md px-6 py-6 bg-white border shadow dark:bg-slate-800 rounded-xl border-slate-100 dark:border-slate-900"
  >
    <div class="flex items-center w-full gap-2 mb-4">
      <span
        class="flex items-center justify-center w-6 h-6 rounded-full bg-woot-75/70 dark:bg-woot-800/40"
      >
        <fluent-icon
          size="14"
          class="flex-shrink-0 text-woot-500 dark:text-woot-500"
          icon="lock-closed"
        />
      </span>
      <span class="text-base font-medium text-slate-900 dark:text-white">
        {{ $t(`${featurePrefix}.PAYWALL.TITLE`) }}
      </span>
    </div>
    <p
      class="text-sm font-normal"
      v-html="$t(`${featurePrefix}.${i18nKey}.AVAILABLE_ON`)"
    />
    <p class="text-sm font-normal">
      {{ $t(`${featurePrefix}.${i18nKey}.UPGRADE_PROMPT`) }}
      <span v-if="!isOnChatwootCloud && !isSuperAdmin">
        {{ $t(`${featurePrefix}.ENTERPRISE_PAYWALL.ASK_ADMIN`) }}
      </span>
    </p>
    <template v-if="isOnChatwootCloud">
      <woot-button
        color-scheme="primary"
        class="w-full mt-2 text-center rounded-xl"
        size="expanded"
        is-expanded
        @click="emit('upgrade')"
      >
        {{ $t(`${featurePrefix}.PAYWALL.UPGRADE_NOW`) }}
      </woot-button>
      <span class="mt-2 text-xs tracking-tight text-center">
        {{ $t(`${featurePrefix}.PAYWALL.CANCEL_ANYTIME`) }}
      </span>
    </template>
    <template v-else-if="isSuperAdmin">
      <a href="/super_admin" class="block w-full">
        <woot-button
          color-scheme="primary"
          class="w-full mt-2 text-center rounded-xl"
          size="expanded"
          is-expanded
        >
          {{ $t(`${featurePrefix}.PAYWALL.UPGRADE_NOW`) }}
        </woot-button>
      </a>
    </template>
  </div>
</template>
