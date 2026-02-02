<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useConfig } from 'dashboard/composables/useConfig';

import SettingsLayout from '../../SettingsLayout.vue';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import CaptainPaywall from 'next/captain/pageComponents/Paywall.vue';
import McpServerCard from 'dashboard/components-next/captain/pageComponents/mcpServer/McpServerCard.vue';
import CreateMcpServerDialog from 'dashboard/components-next/captain/pageComponents/mcpServer/CreateMcpServerDialog.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Policy from 'dashboard/components/policy.vue';

const { t } = useI18n();
const store = useStore();
const { captainEnabled } = useCaptain();
const { isEnterprise, enterprisePlanName } = useConfig();
const { isOnChatwootCloud } = useAccount();

const uiFlags = useMapGetter('captainMcpServers/getUIFlags');
const mcpServers = useMapGetter('captainMcpServers/getRecords');

const isFetching = computed(() => uiFlags.value.fetchingList);
const isUpdating = computed(() => uiFlags.value.updatingItem);

const createDialogRef = ref(null);
const deleteDialogRef = ref(null);
const selectedServer = ref(null);
const dialogType = ref('');

const isFeatureAccessible = computed(() => {
  if (isOnChatwootCloud.value && captainEnabled) return true;
  return isEnterprise && enterprisePlanName === 'enterprise';
});

const fetchMcpServers = () => {
  store.dispatch('captainMcpServers/get');
};

const openCreateDialog = () => {
  dialogType.value = 'create';
  selectedServer.value = null;
  nextTick(() => createDialogRef.value?.dialogRef?.open());
};

const handleEdit = server => {
  dialogType.value = 'edit';
  selectedServer.value = server;
  nextTick(() => createDialogRef.value?.dialogRef?.open());
};

const handleDelete = server => {
  selectedServer.value = server;
  nextTick(() => deleteDialogRef.value?.dialogRef?.open());
};

const handleAction = ({ action, id }) => {
  const server = mcpServers.value.find(s => s.id === id);
  if (action === 'edit') {
    handleEdit(server);
  } else if (action === 'delete') {
    handleDelete(server);
  } else if (action === 'connect') {
    store.dispatch('captainMcpServers/connect', id);
  } else if (action === 'disconnect') {
    store.dispatch('captainMcpServers/disconnect', id);
  } else if (action === 'refresh') {
    store.dispatch('captainMcpServers/refresh', id);
  }
};

const handleDialogClose = () => {
  dialogType.value = '';
  selectedServer.value = null;
};

const onDeleteSuccess = () => {
  selectedServer.value = null;
  fetchMcpServers();
};

onMounted(() => {
  fetchMcpServers();
});
</script>

<template>
  <SettingsLayout
    :is-loading="isFetching"
    :no-records-message="t('CAPTAIN_SETTINGS.MCP_SERVERS.NOT_ENABLED')"
    :loading-message="t('CAPTAIN_SETTINGS.MCP_SERVERS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('CAPTAIN_SETTINGS.MCP_SERVERS.TITLE')"
        :description="t('CAPTAIN_SETTINGS.MCP_SERVERS.DESCRIPTION')"
        icon-name="link"
        feature-name="captain_mcp"
      >
        <template #actions>
          <Policy :permissions="['administrator']">
            <Button
              :label="t('CAPTAIN_SETTINGS.MCP_SERVERS.ADD_NEW')"
              color="blue"
              icon="i-lucide-plus"
              @click="openCreateDialog"
            />
          </Policy>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div
        v-if="captainEnabled && isFeatureAccessible"
        class="flex flex-col gap-4"
      >
        <div
          v-if="mcpServers.length === 0 && !isFetching"
          class="flex flex-col items-center justify-center py-16 text-center"
        >
          <div
            class="w-16 h-16 rounded-2xl bg-n-alpha-2 flex items-center justify-center mb-4"
          >
            <i class="i-lucide-plug text-3xl text-n-slate-11" />
          </div>
          <h3 class="text-lg font-medium text-n-slate-12 mb-2">
            {{ t('CAPTAIN_SETTINGS.MCP_SERVERS.EMPTY.TITLE') }}
          </h3>
          <p class="text-sm text-n-slate-11 max-w-md mb-6">
            {{ t('CAPTAIN_SETTINGS.MCP_SERVERS.EMPTY.DESCRIPTION') }}
          </p>
          <Policy :permissions="['administrator']">
            <Button
              :label="t('CAPTAIN_SETTINGS.MCP_SERVERS.ADD_NEW')"
              color="blue"
              icon="i-lucide-plus"
              @click="openCreateDialog"
            />
          </Policy>
        </div>

        <div v-else class="flex flex-col gap-4">
          <McpServerCard
            v-for="server in mcpServers"
            :key="server.id"
            :server="server"
            :is-updating="isUpdating"
            @action="handleAction"
          />
        </div>
      </div>
      <div v-else>
        <CaptainPaywall />
      </div>
    </template>
  </SettingsLayout>

  <CreateMcpServerDialog
    v-if="dialogType"
    ref="createDialogRef"
    :type="dialogType"
    :selected-server="selectedServer"
    @close="handleDialogClose"
    @created="fetchMcpServers"
  />

  <DeleteDialog
    v-if="selectedServer"
    ref="deleteDialogRef"
    :entity="selectedServer"
    type="McpServers"
    translation-key="MCP_SERVERS"
    @delete-success="onDeleteSuccess"
  />
</template>
