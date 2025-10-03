<script setup>
import { computed, onMounted, ref } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import CustomToolsPageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/CustomToolsPageEmptyState.vue';
import CreateCustomToolDialog from 'dashboard/components-next/captain/pageComponents/customTool/CreateCustomToolDialog.vue';

const store = useStore();

const uiFlags = useMapGetter('captainCustomTools/getUIFlags');
const customTools = useMapGetter('captainCustomTools/getRecords');
const isFetching = computed(() => uiFlags.value.fetchingList);
const customToolsMeta = useMapGetter('captainCustomTools/getMeta');

const createDialogRef = ref(null);

const fetchCustomTools = (page = 1) => {
  store.dispatch('captainCustomTools/get', { page });
};

const onPageChange = page => fetchCustomTools(page);

const openCreateDialog = () => {
  createDialogRef.value.dialogRef.open();
};

onMounted(() => {
  fetchCustomTools();
});
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.CUSTOM_TOOLS.HEADER')"
    :button-label="$t('CAPTAIN.CUSTOM_TOOLS.ADD_NEW')"
    :button-policy="['administrator']"
    :total-count="customToolsMeta.totalCount"
    :current-page="customToolsMeta.page"
    :show-pagination-footer="!isFetching && !!customTools.length"
    :is-fetching="isFetching"
    :is-empty="!customTools.length"
    :feature-flag="FEATURE_FLAGS.CAPTAIN_CUSTOM_TOOLS"
    @update:current-page="onPageChange"
    @button-click="openCreateDialog"
  >
    <template #paywall>
      <CaptainPaywall />
    </template>

    <template #emptyState>
      <CustomToolsPageEmptyState @click="openCreateDialog" />
    </template>

    <template #body>
      <div class="flex flex-col gap-4">
        <div
          v-for="tool in customTools"
          :key="tool.id"
          class="border border-slate-100 dark:border-slate-800 rounded-lg p-4"
        >
          <h3 class="text-base font-medium text-slate-900 dark:text-slate-100">
            {{ tool.title }}
          </h3>
          <p
            v-if="tool.description"
            class="text-sm text-slate-600 dark:text-slate-400 mt-1"
          >
            {{ tool.description }}
          </p>
          <div class="flex items-center gap-2 mt-2">
            <span
              class="text-xs px-2 py-1 rounded bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300"
            >
              {{ tool.http_method }}
            </span>
            <span class="text-xs text-slate-500 dark:text-slate-400 truncate">
              {{ tool.endpoint_url }}
            </span>
          </div>
        </div>
      </div>
    </template>
  </PageLayout>

  <CreateCustomToolDialog ref="createDialogRef" />
</template>
