<script setup>
import { computed, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import CaptainCustomTools from 'dashboard/api/captain/customTools';
import McpServersAPI from 'dashboard/api/captain/mcpServers';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import SettingsHeader from 'dashboard/components-next/captain/pageComponents/settings/SettingsHeader.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

defineProps({
  heading: { type: String, required: true },
  description: { type: String, default: '' },
  buttonLabel: { type: String, default: '' },
  isFetching: { type: Boolean, default: false },
  isEmpty: { type: Boolean, default: false },
  totalCount: { type: Number, default: 0 },
  currentPage: { type: Number, default: 1 },
  showPaginationFooter: { type: Boolean, default: false },
});

const emit = defineEmits(['click', 'update:currentPage']);

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { isFeatureFlagEnabled } = usePolicy();
const globalConfig = useMapGetter('globalConfig/get');

const counts = ref({ installed: null, custom: null, mcp: null });
const assistantId = computed(() => route.params.assistantId);
const hasMcpServers = computed(() =>
  isFeatureFlagEnabled(FEATURE_FLAGS.CAPTAIN_MCP_SERVERS)
);

const tabs = computed(() => [
  {
    id: 'captain_tools_installed',
    icon: 'i-lucide-package-check',
    label: t('CAPTAIN.TOOLS_NAV.INSTALLED'),
    count: counts.value.installed,
  },
  {
    id: 'captain_tools_custom',
    icon: 'i-lucide-wrench',
    label: t('CAPTAIN.TOOLS_NAV.CUSTOM'),
    count: counts.value.custom,
  },
  ...(hasMcpServers.value
    ? [
        {
          id: 'captain_mcp_servers_index',
          icon: 'i-lucide-server',
          label: t('CAPTAIN.TOOLS_NAV.MCP_SERVERS'),
          count: counts.value.mcp,
        },
      ]
    : []),
  ...(globalConfig.value.captainToolsManifestEnabled
    ? [
        {
          id: 'captain_tools_explore',
          icon: 'i-lucide-blocks',
          label: t('CAPTAIN.TOOLS_NAV.CATALOG'),
        },
      ]
    : []),
]);

const openTab = name =>
  router.push({
    name,
    params: {
      accountId: route.params.accountId,
      assistantId: assistantId.value,
    },
  });

// The counts are a guide, so a failed request leaves them out instead of blocking the page
const refreshCounts = async () => {
  const requestedFor = assistantId.value;
  try {
    const [toolsResponse, serversResponse] = await Promise.all([
      CaptainCustomTools.get({ assistantId: requestedFor }),
      hasMcpServers.value
        ? McpServersAPI.get({ assistantId: requestedFor })
        : null,
    ]);
    if (requestedFor !== assistantId.value) return;

    counts.value = {
      installed: toolsResponse.data.meta.installed_count,
      custom: toolsResponse.data.meta.custom_count,
      mcp: serversResponse ? serversResponse.data.payload.length : null,
    };
  } catch {
    counts.value = { installed: null, custom: null, mcp: null };
  }
};

watch([assistantId, hasMcpServers], refreshCounts, { immediate: true });

defineExpose({ refreshCounts });
</script>

<template>
  <PageLayout
    :header-title="
      hasMcpServers
        ? t('SIDEBAR.CAPTAIN_TOOLS_AND_MCP')
        : t('SIDEBAR.CAPTAIN_TOOLS')
    "
    :button-label="buttonLabel"
    :button-policy="['administrator']"
    :feature-flag="FEATURE_FLAGS.CAPTAIN_CUSTOM_TOOLS"
    :total-count="totalCount"
    :current-page="currentPage"
    :show-pagination-footer="showPaginationFooter"
    :show-know-more="false"
    @click="emit('click')"
    @update:current-page="emit('update:currentPage', $event)"
  >
    <template #headerActions>
      <slot name="headerActions" />
    </template>

    <template #paywall>
      <CaptainPaywall feature-prefix="CAPTAIN.CUSTOM_TOOLS" />
    </template>

    <template #body>
      <div
        class="flex flex-col w-full gap-4 md:flex-row md:items-start md:gap-8"
      >
        <!-- Same rail as VerticalTabs, with a count on each list -->
        <nav
          class="flex flex-row w-full gap-1 pb-2 overflow-x-auto no-scrollbar border-b shrink-0 border-n-weak md:sticky md:top-0 md:flex-col md:w-48 md:gap-0.5 md:border-b-0 md:overflow-visible"
        >
          <button
            v-for="tab in tabs"
            :key="tab.id"
            type="button"
            class="flex items-center gap-2 px-2.5 py-2 text-sm text-start transition-colors rounded-lg shrink-0 min-h-9 md:w-full"
            :class="
              route.name === tab.id
                ? 'bg-n-alpha-2 text-n-slate-12 font-medium'
                : 'text-n-slate-11 hover:bg-n-alpha-1 hover:text-n-slate-12'
            "
            :aria-current="route.name === tab.id ? 'page' : undefined"
            @click="openTab(tab.id)"
          >
            <Icon :icon="tab.icon" class="shrink-0 size-4" />
            <span class="flex-1 min-w-0 whitespace-nowrap">
              {{ tab.label }}
            </span>
            <span
              v-if="tab.count != null"
              class="text-xs tabular-nums text-n-slate-10"
            >
              {{ tab.count }}
            </span>
          </button>
        </nav>

        <div class="flex flex-col flex-1 w-full min-w-0 gap-6 pb-8">
          <SettingsHeader :heading="heading" :description="description" />
          <slot name="controls" />
          <div v-if="isFetching" class="flex justify-center py-10">
            <Spinner />
          </div>
          <slot v-else-if="isEmpty" name="emptyState" />
          <slot v-else name="body" />
        </div>
      </div>
    </template>
  </PageLayout>
</template>
