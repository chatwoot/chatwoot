<script setup>
import { useI18n } from 'vue-i18n';
import { DESCRIBE_STATE } from './useFilterRecommendations';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

defineProps({
  // { query, state } from useFilterRecommendations
  status: { type: Object, required: true },
});

const { t } = useI18n();
</script>

<template>
  <p class="flex items-center gap-2 text-sm text-n-slate-11 -mt-2">
    <Spinner v-if="status.state === DESCRIBE_STATE.PENDING" :size="16" />
    {{
      status.state === DESCRIBE_STATE.PENDING
        ? t('FILTER.BUILDING_FILTERS', { query: status.query })
        : t('FILTER.NO_FILTERS_BUILT', { query: status.query })
    }}
  </p>
</template>
