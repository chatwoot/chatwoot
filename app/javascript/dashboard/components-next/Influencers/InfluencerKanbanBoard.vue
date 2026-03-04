<script setup>
import { onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import InfluencerKanbanColumn from './InfluencerKanbanColumn.vue';

defineProps({
  statuses: {
    type: Array,
    default: () => ['discovered', 'enriched', 'approved', 'rejected'],
  },
});

const emit = defineEmits(['select']);

const { t } = useI18n();
const store = useStore();

const statusLabels = {
  discovered: t('INFLUENCER.KANBAN.STATUS_DISCOVERED'),
  enriched: t('INFLUENCER.KANBAN.STATUS_ENRICHED'),
  approved: t('INFLUENCER.KANBAN.STATUS_APPROVED'),
  rejected: t('INFLUENCER.KANBAN.STATUS_REJECTED'),
  contacted: t('INFLUENCER.KANBAN.STATUS_CONTACTED'),
  confirmed: t('INFLUENCER.KANBAN.STATUS_CONFIRMED'),
};

const getColumn = status => {
  return store.getters['influencerProfiles/getKanbanColumn'](status);
};

onMounted(() => {
  store.dispatch('influencerProfiles/refreshAllKanbanColumns');
});

const loadMore = status => {
  store.dispatch('influencerProfiles/loadMoreKanban', { status });
};

const handleSelect = profile => {
  emit('select', profile);
};

const handleRetryApify = profileId => {
  store.dispatch('influencerProfiles/retryApify', { id: profileId });
};
</script>

<template>
  <div class="flex flex-col h-full">
    <div class="flex gap-4 overflow-x-auto items-start flex-1 p-4">
      <InfluencerKanbanColumn
        v-for="status in statuses"
        :key="status"
        :status="status"
        :label="statusLabels[status] || status"
        :profiles="getColumn(status).records"
        :count="getColumn(status).meta.count"
        :has-more="getColumn(status).meta.hasMore"
        :loading="getColumn(status).loading"
        @select="handleSelect"
        @load-more="loadMore(status)"
        @retry-apify="handleRetryApify"
      />
    </div>
  </div>
</template>
