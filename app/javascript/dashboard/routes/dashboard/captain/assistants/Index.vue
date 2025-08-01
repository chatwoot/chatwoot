<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import Auth from 'dashboard/api/auth';
import { useAccount } from 'dashboard/composables/useAccount';
import { getAgentManagerBaseUrl } from 'dashboard/constants/agentManager';

import AssistantCard from 'dashboard/components-next/captain/assistant/AssistantCard.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import CreateAssistantDialog from 'dashboard/components-next/captain/pageComponents/assistant/CreateAssistantDialog.vue';
import AssistantPageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/AssistantPageEmptyState.vue';
import FeatureSpotlightPopover from 'dashboard/components-next/feature-spotlight/FeatureSpotlightPopover.vue';
import LimitBanner from 'dashboard/components-next/captain/pageComponents/response/LimitBanner.vue';
import { useRouter } from 'vue-router';

const router = useRouter();
const { accountId } = useAccount();

const assistants = ref([]);
const assistantsMeta = ref({ totalCount: 0, page: 1 });
const isFetching = ref(false);

const dialogType = ref('');
const selectedAssistant = ref(null);
const deleteAssistantDialog = ref(null);
const createAssistantDialog = ref(null);

const fetchAssistants = async (page = 1) => {
  isFetching.value = true;
  try {
    const authData = Auth.getAuthData();
    const headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-CHATWOOT-ACCOUNT-ID': accountId.value,
      'Access-Token': authData['access-token'],
      'Authorization': `${authData['token-type']} ${authData['access-token']}`,
    };
    const baseUrl = getAgentManagerBaseUrl();
    const response = await fetch(`${baseUrl}/agent-manager/api/v1/agents?page=${page}`, {
      method: 'GET',
      headers: headers,
    });
    if (!response.ok) {
      throw new Error(`API request failed: ${response.status} ${response.statusText}`);
    }
    const result = await response.json();
    const dataArray = Array.isArray(result) ? result : (result.data || []);
    assistants.value = dataArray.map(a => {
      let createdAt, updatedAt;
      if (typeof a.created_at === 'string') {
        let iso = a.created_at.replace(/(\.\d{3})\d+/, '$1');
        if (!iso.endsWith('Z')) iso += 'Z';
        createdAt = Date.parse(iso) / 1000;
      } else if (typeof a.created_at === 'number') {
        createdAt = a.created_at < 1e12 ? a.created_at : Math.floor(a.created_at / 1000);
      } else {
        createdAt = 0;
      }
      if (typeof a.updated_at === 'string') {
        let iso = a.updated_at.replace(/(\.\d{3})\d+/, '$1');
        if (!iso.endsWith('Z')) iso += 'Z';
        updatedAt = Date.parse(iso) / 1000;
      } else if (typeof a.updated_at === 'number') {
        updatedAt = a.updated_at < 1e12 ? a.updated_at : Math.floor(a.updated_at / 1000);
      } else {
        updatedAt = 0;
      }
      return {
        ...a,
        updated_at: updatedAt,
        created_at: createdAt,
      };
    });
    assistantsMeta.value = {
      totalCount: result.total_count || dataArray.length,
      page: page,
    };
  } catch (error) {
    console.error('❌ Error fetching assistants:', error);
  } finally {
    isFetching.value = false;
  }
};

const handleDelete = () => {
  deleteAssistantDialog.value.dialogRef.open();
};

const handleCreate = () => {
  dialogType.value = 'create';
  nextTick(() => createAssistantDialog.value.dialogRef.open());
};

const handleEdit = (assistant) => {
  selectedAssistant.value = assistant;
  dialogType.value = 'edit';
  nextTick(() => createAssistantDialog.value.dialogRef.open());
};

const handleAction = ({ action, id }) => {
  selectedAssistant.value = assistants.value.find(a => id === a.id);
  nextTick(() => {
    if (action === 'delete') {
      handleDelete();
    }
    if (action === 'edit') {
      handleEdit(selectedAssistant.value);
    }
  });
};

const handleCreateClose = () => {
  dialogType.value = '';
  selectedAssistant.value = null;
  fetchAssistants(assistantsMeta.value.page);
};

const handleDeleteSuccess = () => {
  if (deleteAssistantDialog.value && deleteAssistantDialog.value.dialogRef) {
    deleteAssistantDialog.value.dialogRef.close();
  }
  selectedAssistant.value = null;
  fetchAssistants(assistantsMeta.value.page);
};

const onPageChange = page => fetchAssistants(page);

onMounted(() => fetchAssistants());
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.ASSISTANTS.HEADER')"
    :button-label="$t('CAPTAIN.ASSISTANTS.ADD_NEW')"
    :button-policy="['administrator']"
    :total-count="assistantsMeta.totalCount"
    :current-page="assistantsMeta.page"
    :show-pagination-footer="!isFetching && !!assistants.length"
    :is-fetching="isFetching"
    :is-empty="!assistants.length"
    :feature-flag="FEATURE_FLAGS.CAPTAIN"
    @update:current-page="onPageChange"
    @click="handleCreate"
  >
    <template #emptyState>
      <AssistantPageEmptyState @click="handleCreate" />
    </template>

    <template #paywall>
      <CaptainPaywall />
    </template>

    <template #body>
      <LimitBanner class="mb-5" />

      <div class="flex flex-col gap-4">
        <AssistantCard
          v-for="assistant in assistants"
          :id="assistant.id"
          :key="assistant.id"
          :name="assistant.name"
          :description="assistant.description"
          :updated-at="assistant.updated_at"
          :created-at="assistant.created_at"
          @action="handleAction"
        />
      </div>
    </template>

    <DeleteDialog
      v-if="selectedAssistant"
      ref="deleteAssistantDialog"
      :entity="selectedAssistant"
      type="Assistants"
      @delete-success="handleDeleteSuccess"
    />

    <CreateAssistantDialog
      v-if="dialogType"
      ref="createAssistantDialog"
      :type="dialogType"
      :selected-assistant="selectedAssistant"
      @close="handleCreateClose"
    />
  </PageLayout>
</template>
