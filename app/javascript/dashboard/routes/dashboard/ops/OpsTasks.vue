<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const homeUrl = computed(() => window.chatwootConfig?.coroHomeUrl || '');
</script>

<template>
  <div class="flex h-full min-h-0 w-full flex-col bg-n-background">
    <div
      v-if="!homeUrl"
      class="flex flex-1 items-center justify-center p-6 text-sm text-n-slate-11"
    >
      {{ t('OPS_TASKS.MISSING_URL') }}
    </div>
    <iframe
      v-else
      :src="homeUrl"
      :title="t('OPS_TASKS.IFRAME_TITLE')"
      class="h-full w-full flex-1 border-0"
      allow="clipboard-read; clipboard-write"
    />
  </div>
</template>
