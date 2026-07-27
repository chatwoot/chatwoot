<script setup>
import { computed } from 'vue';
import { useConfigStore } from 'widget-v2/stores/config';

const configStore = useConfigStore();

const show = computed(() => !configStore.channel.disable_branding);
const brandName = computed(
  () => configStore.globalConfig.BRAND_NAME || 'Chatwoot'
);
const brandUrl = computed(
  () => configStore.globalConfig.WIDGET_BRAND_URL || 'https://www.chatwoot.com'
);
</script>

<template>
  <a
    v-if="show"
    :href="brandUrl"
    target="_blank"
    rel="noreferrer noopener"
    class="flex items-center justify-center gap-1 py-1.5 text-xxs text-cw-text-faint hover:text-cw-text-muted"
  >
    {{ $t('COMMON.POWERED_BY') }} {{ brandName }}
  </a>
</template>
