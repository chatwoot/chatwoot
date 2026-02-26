<script setup>
import { computed, onMounted, ref, nextTick, watch } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import CustomToolsPageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/CustomToolsPageEmptyState.vue';
import CreateCustomToolDialog from 'dashboard/components-next/captain/pageComponents/customTool/CreateCustomToolDialog.vue';
import CustomToolCard from 'dashboard/components-next/captain/pageComponents/customTool/CustomToolCard.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import AssistantMcpServerCard from 'dashboard/components-next/captain/pageComponents/mcpServer/AssistantMcpServerCard.vue';
import ConnectMcpServerDialog from 'dashboard/components-next/captain/pageComponents/mcpServer/ConnectMcpServerDialog.vue';

const store = useStore();
const route = useRoute();
const { t } = useI18n();

const uiFlags = useMapGetter('captainCustomTools/getUIFlags');
const customTools = useMapGetter('captainCustomTools/getRecords');
const assistantMcpServers = useMapGetter(
  'captainAssistantMcpServers/getRecords'
);
const assistantMcpUiFlags = useMapGetter(
  'captainAssistantMcpServers/getUIFlags'
);
const mcpServersUiFlags = useMapGetter('captainMcpServers/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingList);
const isFetchingMcp = computed(
  () =>
    assistantMcpUiFlags.value.fetchingList ||
    mcpServersUiFlags.value.fetchingList
);
const customToolsMeta = useMapGetter('captainCustomTools/getMeta');

const createDialogRef = ref(null);
const deleteDialogRef = ref(null);
const detachDialogRef = ref(null);
const connectMcpServerDialog = ref(null);
const selectedTool = ref(null);
const selectedMcpServer = ref(null);
const dialogType = ref('');
const mcpDialogType = ref('');

const assistantId = computed(() => Number(route.params.assistantId));

const fetchCustomTools = (page = 1) => {
  store.dispatch('captainCustomTools/get', { page });
};

const fetchMcpServers = () => {
  store.dispatch('captainMcpServers/get');
};

const fetchAssistantMcpServers = id => {
  if (!id) return;
  store.dispatch('captainAssistantMcpServers/get', { assistantId: id });
};

const onPageChange = page => fetchCustomTools(page);

const openCreateDialog = () => {
  dialogType.value = 'create';
  selectedTool.value = null;
  nextTick(() => createDialogRef.value.dialogRef.open());
};

const openMcpDialog = () => {
  mcpDialogType.value = 'create';
  nextTick(() => connectMcpServerDialog.value.dialogRef.open());
};

const handleEdit = tool => {
  dialogType.value = 'edit';
  selectedTool.value = tool;
  nextTick(() => createDialogRef.value.dialogRef.open());
};

const handleDelete = tool => {
  selectedTool.value = tool;
  nextTick(() => deleteDialogRef.value.dialogRef.open());
};

const handleDetach = record => {
  selectedMcpServer.value = record;
  nextTick(() => detachDialogRef.value.dialogRef.open());
};

const handleAction = ({ action, id }) => {
  const tool = customTools.value.find(toolItem => toolItem.id === id);
  if (action === 'edit') {
    handleEdit(tool);
  } else if (action === 'delete') {
    handleDelete(tool);
  }
};

const handleDialogClose = () => {
  dialogType.value = '';
  selectedTool.value = null;
};

const handleMcpDialogClose = () => {
  mcpDialogType.value = '';
};

const handleDetachSuccess = () => {
  selectedMcpServer.value = null;
  fetchAssistantMcpServers(assistantId.value);
};

const onDeleteSuccess = () => {
  selectedTool.value = null;
  // Check if page will be empty after deletion
  if (customTools.value.length === 1 && customToolsMeta.value.page > 1) {
    // Go to previous page if current page will be empty
    onPageChange(customToolsMeta.value.page - 1);
  } else {
    // Refresh current page
    fetchCustomTools(customToolsMeta.value.page);
  }
};

const isPageEmpty = computed(() => false);

onMounted(() => {
  fetchMcpServers();
  fetchCustomTools();
});

watch(
  assistantId,
  newId => {
    fetchAssistantMcpServers(newId);
  },
  { immediate: true }
);
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.CUSTOM_TOOLS.HEADER')"
    :button-label="$t('CAPTAIN.CUSTOM_TOOLS.ADD_NEW')"
    :button-policy="['administrator']"
    :total-count="customToolsMeta.totalCount"
    :current-page="customToolsMeta.page"
    :show-pagination-footer="!isFetching && !!customTools.length"
    :is-fetching="isFetching || isFetchingMcp"
    :is-empty="isPageEmpty"
    :feature-flag="FEATURE_FLAGS.CAPTAIN_V2"
    :show-know-more="false"
    @update:current-page="onPageChange"
    @click="openCreateDialog"
  >
    <template #paywall>
      <CaptainPaywall />
    </template>

    <template #body>
      <div class="flex flex-col gap-8">
        <section class="flex flex-col gap-4">
          <div class="flex items-start justify-between gap-4">
            <div class="flex flex-col gap-1">
              <h3 class="text-base font-medium text-n-slate-12">
                {{ t('CAPTAIN.MCP_SERVERS.HEADER') }}
              </h3>
              <p class="text-sm text-n-slate-11">
                {{ t('CAPTAIN.MCP_SERVERS.DESCRIPTION') }}
              </p>
            </div>
            <Button
              color="blue"
              size="sm"
              icon="i-lucide-plus"
              :label="t('CAPTAIN.MCP_SERVERS.ADD_NEW')"
              @click="openMcpDialog"
            />
          </div>

          <div
            v-if="!assistantMcpServers.length && !isFetchingMcp"
            class="rounded-xl border border-n-container bg-n-solid-2 p-6 text-center"
          >
            <h4 class="text-sm font-medium text-n-slate-12">
              {{ t('CAPTAIN.MCP_SERVERS.EMPTY.TITLE') }}
            </h4>
            <p class="text-xs text-n-slate-11 mt-1">
              {{ t('CAPTAIN.MCP_SERVERS.EMPTY.DESCRIPTION') }}
            </p>
          </div>

          <div v-else class="flex flex-col gap-4">
            <AssistantMcpServerCard
              v-for="record in assistantMcpServers"
              :key="record.id"
              :record="record"
              @detach="handleDetach"
            />
          </div>
        </section>

        <section class="flex flex-col gap-4">
          <div class="flex items-center justify-between gap-4">
            <h3 class="text-base font-medium text-n-slate-12">
              {{ t('CAPTAIN.CUSTOM_TOOLS.HEADER') }}
            </h3>
            <Button
              color="blue"
              size="sm"
              icon="i-lucide-plus"
              :label="t('CAPTAIN.CUSTOM_TOOLS.ADD_NEW')"
              @click="openCreateDialog"
            />
          </div>

          <div v-if="!customTools.length && !isFetching" class="pt-2">
            <CustomToolsPageEmptyState @click="openCreateDialog" />
          </div>

          <div v-else class="flex flex-col gap-4">
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
        </section>
      </div>
    </template>
  </PageLayout>

  <CreateCustomToolDialog
    v-if="dialogType"
    ref="createDialogRef"
    :type="dialogType"
    :selected-tool="selectedTool"
    @close="handleDialogClose"
  />

  <DeleteDialog
    v-if="selectedTool"
    ref="deleteDialogRef"
    :entity="selectedTool"
    type="CustomTools"
    translation-key="CUSTOM_TOOLS"
    @delete-success="onDeleteSuccess"
  />

  <DeleteDialog
    v-if="selectedMcpServer"
    ref="detachDialogRef"
    :entity="selectedMcpServer"
    :delete-payload="{
      assistantId: assistantId,
      id: selectedMcpServer.id,
    }"
    type="AssistantMcpServers"
    translation-key="ASSISTANT_MCP_SERVERS"
    @delete-success="handleDetachSuccess"
  />

  <ConnectMcpServerDialog
    v-if="mcpDialogType"
    ref="connectMcpServerDialog"
    :assistant-id="assistantId"
    @close="handleMcpDialogClose"
  />
</template>
