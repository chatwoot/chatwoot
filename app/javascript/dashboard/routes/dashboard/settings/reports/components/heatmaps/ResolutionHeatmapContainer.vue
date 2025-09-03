<script setup>
import BaseHeatmapContainer from './BaseHeatmapContainer.vue';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
</script>

<template>
  <BaseHeatmapContainer
    metric="resolutions_count"
    :title="t('OVERVIEW_REPORTS.RESOLUTION_HEATMAP.HEADER')"
    download-title="resolution_heatmap"
    store-getter="getAccountResolutionHeatmapData"
    store-action="fetchAccountResolutionHeatmap"
    ui-flag-key="isFetchingAccountResolutionsHeatmap"
    color-scheme="green"
  />
</template>
