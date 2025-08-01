<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Auth from 'dashboard/api/auth';
import { useAccount } from 'dashboard/composables/useAccount';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import ToolItem from './ToolItem.vue';
import { getAgentManagerBaseUrl } from 'dashboard/constants/agentManager';

const { t } = useI18n();
const { accountId } = useAccount();

const tools = ref([]); // List of tools from backend
const toolsMeta = ref({ totalCount: 0, page: 1 }); // Metadata
const isFetching = ref(false);
const itemsPerPage = 15;

const fetchTools = async (page = 1) => {
  isFetching.value = true;
  try {
    // Get authentication data
    const authData = Auth.getAuthData();
    if (!authData) {
      throw new Error('Authentication data not available');
    }

    // Prepare headers for API request
    const headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-CHATWOOT-ACCOUNT-ID': accountId.value,
      'Access-Token': authData['access-token'],
      'Authorization': `${authData['token-type']} ${authData['access-token']}`,
    };

    // Use centralized base URL with hardcoded endpoint
    const baseUrl = getAgentManagerBaseUrl();
    const response = await fetch(`${baseUrl}/agent-manager/api/v1/tools?page=${page}`, {
      method: 'GET',
      headers: headers,
    });

    if (!response.ok) {
      throw new Error(`API request failed: ${response.status} ${response.statusText}`);
    }

    const result = await response.json();
    tools.value = result.data;
    console.debug('[Tools/Index.vue] All tools fetched from backend:', tools.value);
    toolsMeta.value = {
      totalCount: result.data.length, // Use result.total_count if available from backend
      page: page,
    };
  } catch (error) {
    console.error('Error fetching tools:', error);
    // You might want to show an error message to the user here
  } finally {
    isFetching.value = false;
  }
};

const paginatedTools = computed(() => {
  const start = (toolsMeta.value.page - 1) * itemsPerPage;
  const end = start + itemsPerPage;
  return tools.value.slice(start, end);
});

const onPageChange = page => fetchTools(page);

fetchTools(1);
</script>

<template>
  <PageLayout
    :header-title="t('CAPTAIN.TOOLS.HEADER')"
    :button-label="''"
    :total-count="toolsMeta.totalCount"
    :current-page="toolsMeta.page"
    :show-pagination-footer="!isFetching && !!paginatedTools.length"
    :is-fetching="isFetching"
    :is-empty="!paginatedTools.length"
    @update:current-page="onPageChange"
  >
    <template #body>
      <p class="mb-4 text-sm text-slate-700 dark:text-slate-200 -mt-2">
        {{ t('CAPTAIN.TOOLS.DESCRIPTION') }}
      </p>
      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        <ToolItem
          v-for="tool in paginatedTools"
          :key="tool.id"
          :id="tool.id"
          :name="tool.name"
          :description="tool.description"
          :enabled="tool.is_integrated"
        />
      </div>
    </template>
  </PageLayout>
</template>
