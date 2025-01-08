<script setup>
import { computed, onMounted } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import ResponseCard from 'dashboard/components-next/captain/assistant/ResponseCard.vue';
const store = useStore();

const uiFlags = useMapGetter('captainResponses/getUIFlags');
const responseMeta = useMapGetter('captainResponses/getMeta');
const responses = useMapGetter('captainResponses/getCaptainResponses');
const isFetching = computed(() => uiFlags.value.fetchingList);

const fetchResponses = (page = 1) => {
  store.dispatch('captainResponses/get', { page });
};

const onPageChange = page => fetchResponses(page);

onMounted(() => fetchResponses());
</script>

<template>
  <PageLayout
    :total-count="responseMeta.totalCount"
    :current-page="responseMeta.page"
    :header-title="$t('CAPTAIN.RESPONSES.HEADER')"
    :button-label="$t('CAPTAIN.RESPONSES.ADD_NEW')"
    :show-pagination-footer="!isFetching && responses.length"
    @update:current-page="onPageChange"
  >
    <div
      v-if="isFetching"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <div v-else-if="responses.length" class="flex flex-col gap-4">
      <ResponseCard
        v-for="response in responses"
        :id="response.id"
        :key="response.id"
        :question="response.question"
        :answer="response.answer"
        :assistant="response.assistant"
        :created-at="response.created_at"
      />
    </div>

    <div v-else>{{ 'No responses found' }}</div>
  </PageLayout>
</template>
