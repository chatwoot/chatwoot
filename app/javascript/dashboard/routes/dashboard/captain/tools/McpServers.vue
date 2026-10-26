<script setup>
import { computed, nextTick, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import McpServersAPI from 'dashboard/api/captain/mcpServers';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import McpServerCard from 'dashboard/components-next/captain/pageComponents/mcpServer/McpServerCard.vue';
import ConnectMcpServerDialog from 'dashboard/components-next/captain/pageComponents/mcpServer/ConnectMcpServerDialog.vue';

const SIGN_IN_RESULTS = { SUCCESS: 'success', FAILED: 'failed' };

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { shouldShowPaywall } = usePolicy();
const { run, isPending } = useAbortableRequest();

const assistantId = computed(() => route.params.assistantId);
const servers = ref([]);
const connectDialogRef = ref(null);
const deleteDialogRef = ref(null);
const serverToDelete = ref(null);
const isDeleting = ref(false);
const pendingToggleIds = ref(new Set());

const showPaywall = computed(() =>
  shouldShowPaywall(FEATURE_FLAGS.CAPTAIN_CUSTOM_TOOLS)
);

const backUrl = computed(() => ({
  name: 'captain_tools_index',
  params: {
    accountId: route.params.accountId,
    assistantId: assistantId.value,
  },
}));

const fetchServers = async () => {
  try {
    const response = await run(signal =>
      McpServersAPI.get({ assistantId: assistantId.value, signal })
    );
    if (!response) return false;
    servers.value = response.data.payload;
    return true;
  } catch {
    useAlert(t('CAPTAIN.MCP_SERVERS.LOAD_ERROR'));
    return false;
  }
};

const openConnectDialog = () => connectDialogRef.value.open(null);

const startSignIn = async server => {
  try {
    const { data } = await McpServersAPI.authorizationUrl({
      id: server.id,
      assistantId: assistantId.value,
    });
    window.location.href = data.url;
  } catch (error) {
    useAlert(
      parseAPIErrorResponse(error) || t('CAPTAIN.MCP_SERVERS.SIGN_IN.ERROR')
    );
  }
};

const handleAction = ({ action, server }) => {
  if (action === 'manage') connectDialogRef.value.open(server);
  if (action === 'sign_in') startSignIn(server);
  if (action === 'delete') {
    serverToDelete.value = server;
    nextTick(() => deleteDialogRef.value.open());
  }
};

const setTogglePending = (id, pending) => {
  const ids = new Set(pendingToggleIds.value);
  if (pending) ids.add(id);
  else ids.delete(id);
  pendingToggleIds.value = ids;
};

const toggleServer = async ({ id, enabled }) => {
  setTogglePending(id, true);
  try {
    await McpServersAPI.update(id, { assistantId: assistantId.value, enabled });
    useAlert(
      enabled
        ? t('CAPTAIN.MCP_SERVERS.TOGGLE.ENABLED')
        : t('CAPTAIN.MCP_SERVERS.TOGGLE.DISABLED')
    );
    await fetchServers();
  } catch (error) {
    useAlert(
      parseAPIErrorResponse(error) || t('CAPTAIN.MCP_SERVERS.TOGGLE.ERROR')
    );
  } finally {
    setTogglePending(id, false);
  }
};

const deleteServer = async () => {
  isDeleting.value = true;
  try {
    await McpServersAPI.delete({
      id: serverToDelete.value.id,
      assistantId: assistantId.value,
    });
    useAlert(t('CAPTAIN.MCP_SERVERS.DELETE.SUCCESS'));
    deleteDialogRef.value.close();
    await fetchServers();
  } catch (error) {
    useAlert(
      parseAPIErrorResponse(error) || t('CAPTAIN.MCP_SERVERS.DELETE.ERROR')
    );
  } finally {
    isDeleting.value = false;
  }
};

// The OAuth callback lands here with the result. A successful sign-in opens the tool picker for that server.
const handleSignInResult = async () => {
  const { sign_in: result, mcp_server_id: serverId } = route.query;
  if (!result) return;

  router.replace({ query: {} });
  if (result === SIGN_IN_RESULTS.FAILED) {
    useAlert(t('CAPTAIN.MCP_SERVERS.SIGN_IN.FAILED'));
    return;
  }

  useAlert(t('CAPTAIN.MCP_SERVERS.SIGN_IN.SUCCESS'));
  const server = servers.value.find(item => item.id === Number(serverId));
  if (server) connectDialogRef.value.open(server);
};

// On a full reload, account features load after mount, so the page waits for access before it fetches.
// The sign-in result is handled after that first fetch, so the picker opens for the server that just signed in.
watch(
  [assistantId, showPaywall],
  async () => {
    if (showPaywall.value) return;
    if (await fetchServers()) handleSignInResult();
  },
  { immediate: true }
);
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.MCP_SERVERS.HEADER')"
    :button-label="$t('CAPTAIN.MCP_SERVERS.CONNECT')"
    :button-policy="['administrator']"
    :back-url="backUrl"
    :feature-flag="FEATURE_FLAGS.CAPTAIN_CUSTOM_TOOLS"
    :is-fetching="isPending && !servers.length"
    :is-empty="!servers.length"
    :show-pagination-footer="false"
    :show-know-more="false"
    @click="openConnectDialog"
  >
    <template #paywall>
      <CaptainPaywall feature-prefix="CAPTAIN.CUSTOM_TOOLS" />
    </template>

    <template #emptyState>
      <div class="flex flex-col items-center gap-2 py-16 text-center">
        <span class="text-base font-medium text-n-slate-12">
          {{ $t('CAPTAIN.MCP_SERVERS.EMPTY_STATE.TITLE') }}
        </span>
        <span class="text-sm text-n-slate-11 max-w-md">
          {{ $t('CAPTAIN.MCP_SERVERS.EMPTY_STATE.SUBTITLE') }}
        </span>
      </div>
    </template>

    <template #body>
      <div class="flex flex-col gap-4">
        <McpServerCard
          v-for="server in servers"
          :key="server.id"
          :server="server"
          :is-updating="pendingToggleIds.has(server.id)"
          @action="handleAction"
          @toggle="toggleServer"
        />
      </div>
    </template>
  </PageLayout>

  <ConnectMcpServerDialog
    ref="connectDialogRef"
    :assistant-id="assistantId"
    @saved="fetchServers"
  />

  <Dialog
    ref="deleteDialogRef"
    type="alert"
    :title="
      t('CAPTAIN.MCP_SERVERS.DELETE.TITLE', { name: serverToDelete?.name })
    "
    :description="t('CAPTAIN.MCP_SERVERS.DELETE.DESCRIPTION')"
    :confirm-button-label="t('CAPTAIN.MCP_SERVERS.DELETE.CONFIRM')"
    :is-loading="isDeleting"
    @confirm="deleteServer"
  />
</template>
