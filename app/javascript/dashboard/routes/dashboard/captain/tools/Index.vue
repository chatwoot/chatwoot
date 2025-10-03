<script setup>
import { computed, onMounted, ref } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import CustomToolsPageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/CustomToolsPageEmptyState.vue';
import CreateCustomToolDialog from 'dashboard/components-next/captain/pageComponents/customTool/CreateCustomToolDialog.vue';
import CustomToolCard from 'dashboard/components-next/captain/pageComponents/customTool/CustomToolCard.vue';

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

const handleAction = ({ action, id }) => {
  // TODO: Implement edit and delete actions
  // eslint-disable-next-line no-console
  console.log('Action:', action, 'ID:', id);
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
    @click="openCreateDialog"
  >
    <template #paywall>
      <CaptainPaywall />
    </template>

    <template #emptyState>
      <CustomToolsPageEmptyState @click="openCreateDialog" />
    </template>

    <template #body>
      <div class="flex flex-col gap-4">
        <CustomToolCard
          v-for="tool in customTools"
          :id="tool.id"
          :key="tool.id"
          :title="tool.title"
          :description="tool.description"
          :endpoint-url="tool.endpoint_url"
          :http-method="tool.http_method"
          :auth-type="tool.auth_type"
          :param-schema="tool.param_schema"
          :enabled="tool.enabled"
          :created-at="tool.created_at"
          :updated-at="tool.updated_at"
          @action="handleAction"
        />
      </div>
    </template>
  </PageLayout>

  <CreateCustomToolDialog ref="createDialogRef" />
</template>
