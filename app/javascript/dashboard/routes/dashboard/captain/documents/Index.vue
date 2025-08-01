<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import Auth from 'dashboard/api/auth';
import { useAccount } from 'dashboard/composables/useAccount';
import { getAgentManagerBaseUrl } from 'dashboard/constants/agentManager';

import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import DocumentCard from 'dashboard/components-next/captain/assistant/DocumentCard.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import RelatedResponses from 'dashboard/components-next/captain/pageComponents/document/RelatedResponses.vue';
import CreateDocumentDialog from 'dashboard/components-next/captain/pageComponents/document/CreateDocumentDialog.vue';
import DocumentPageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/DocumentPageEmptyState.vue';
import FeatureSpotlightPopover from 'dashboard/components-next/feature-spotlight/FeatureSpotlightPopover.vue';
import LimitBanner from 'dashboard/components-next/captain/pageComponents/document/LimitBanner.vue';
import DocumentForm from 'dashboard/components-next/captain/pageComponents/document/DocumentForm.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const store = useStore();
const { accountId } = useAccount();

const assistants = useMapGetter('captainAssistants/getRecords');
const datasources = ref([]);
const datasourcesMeta = ref({ totalCount: 0, page: 1 });
const isFetching = ref(false);

const selectedDocument = ref(null);
const deleteDocumentDialog = ref(null);

const showRelatedResponses = ref(false);
const showCreateDialog = ref(false);
const createDocumentDialog = ref(null);
const relationQuestionDialog = ref(null);
const showEditDialog = ref(false);
const editingDocument = ref(null);
const editDocumentDialog = ref(null);

const fetchDatasources = async (page = 1) => {
  isFetching.value = true;
  try {
    const authData = Auth.getAuthData();
    if (!authData) {
      throw new Error('Authentication data not available');
    }
    
    const headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-CHATWOOT-ACCOUNT-ID': accountId.value,
      'Access-Token': authData['access-token'],
      'Authorization': `${authData['token-type']} ${authData['access-token']}`,
    };
    
    const baseUrl = getAgentManagerBaseUrl();
    const response = await fetch(`${baseUrl}/agent-manager/api/v1/datasources?page=${page}`, {
      method: 'GET',
      headers: headers,
    });
    
    if (!response.ok) {
      throw new Error(`API request failed: ${response.status} ${response.statusText}`);
    }
    
    const result = await response.json();
    
    // Support both { data: [...] } and [...] as API responses
    const dataArray = Array.isArray(result) ? result : (result.data || []);
    datasources.value = dataArray.map(ds => {
      let createdAt;
      if (typeof ds.created_at === 'string') {
        let iso = ds.created_at.replace(/(\.\d{3})\d+/, '$1');
        if (!iso.endsWith('Z')) iso += 'Z';
        createdAt = Date.parse(iso);
      } else if (typeof ds.created_at === 'number') {
        createdAt = ds.created_at < 1e12 ? ds.created_at * 1000 : ds.created_at;
      } else {
        createdAt = Date.now();
      }
      if (createdAt > Date.now()) createdAt = Date.now();
      const createdAtSeconds = Math.floor(createdAt / 1000);
      return {
        id: ds.id,
        filename: ds.name || 'Untitled Document',
        externalLink: ds.documents && ds.documents[0] ? ds.documents[0].name : (ds.web_url || ''),
        createdAt: createdAtSeconds,
        assistant: null,
        description: ds.description || '',
        type: ds.type || (ds.web_url ? 'web_url' : ''),
        status: ds.status || '', // Pass status from backend
      };
    });
    console.log('[fetchDatasources] Processed datasources:', datasources.value.map(ds => ({ id: ds.id, name: ds.filename, status: ds.status })));
    datasourcesMeta.value = {
      totalCount: result.total_count || dataArray.length,
      page: page,
    };
    
  } catch (error) {
    console.error('❌ Error fetching datasources:', error);
  } finally {
    isFetching.value = false;
  }
};

const handleDelete = () => {
  deleteDocumentDialog.value.dialogRef.open();
};

const handleEdit = (doc) => {
  console.log('[handleEdit] called with doc:', doc);
  editingDocument.value = {
    id: doc.id,
    filename: doc.filename || '',
    description: doc.description || '',
    type: doc.type || (doc.externalLink ? (doc.externalLink.startsWith('http') ? 'web_url' : 'url') : 'file'),
    url: doc.externalLink || '',
  };
  showEditDialog.value = true;
  nextTick(() => {
    editDocumentDialog.value?.open();
  });
  console.log('[handleEdit] editingDocument:', editingDocument.value);
  console.log('[handleEdit] showEditDialog:', showEditDialog.value);
};

const handleEditDialogClose = () => {
  showEditDialog.value = false;
  editingDocument.value = null;
};

const handleEditSubmit = async (editPayload) => {
  if (!editingDocument.value) return;
  const authData = Auth.getAuthData();
  const id = editingDocument.value.id;
  try {
    let response;
    console.log('[Edit Submit] Payload being sent to backend:', editPayload);
    const baseUrl = getAgentManagerBaseUrl();
    if (editPayload instanceof FormData) {
      response = await fetch(`${baseUrl}/agent-manager/api/v1/datasources/${id}`, {
        method: 'PUT',
        body: editPayload,
        headers: {
          'X-CHATWOOT-ACCOUNT-ID': accountId.value,
          'Access-Token': authData['access-token'],
          'Authorization': `${authData['token-type']} ${authData['access-token']}`,
        },
      });
    } else {
      response = await fetch(`${baseUrl}/agent-manager/api/v1/datasources/${id}`, {
        method: 'PUT',
        body: JSON.stringify(editPayload),
        headers: {
          'Content-Type': 'application/json',
          'X-CHATWOOT-ACCOUNT-ID': accountId.value,
          'Access-Token': authData['access-token'],
          'Authorization': `${authData['token-type']} ${authData['access-token']}`,
        },
      });
    }
    if (!response.ok) throw new Error('Failed to update document');
    handleEditDialogClose();
    fetchDatasources();
  } catch (error) {
    alert('Failed to update document');
  }
};

const handleShowRelatedDocument = () => {
  showRelatedResponses.value = true;
  nextTick(() => relationQuestionDialog.value.dialogRef.open());
};

const handleCreateDocument = () => {
  showCreateDialog.value = true;
  nextTick(() => createDocumentDialog.value.dialogRef.open());
};

const handleRelatedResponseClose = () => {
  showRelatedResponses.value = false;
};

const handleCreateDialogClose = () => {
  showCreateDialog.value = false;
};

const handleAction = ({ action, id }) => {
  console.log('[handleAction] action:', action, 'id:', id);
  selectedDocument.value = datasources.value.find(
    datasource => id === datasource.id
  );
  console.log('[handleAction] selectedDocument:', selectedDocument.value);
  nextTick(() => {
    if (action === 'delete') {
      handleDelete();
    } else if (action === 'viewRelatedQuestions') {
      handleShowRelatedDocument();
    } else if (action === 'edit') {
      handleEdit(selectedDocument.value);
    }
  });
};

const onPageChange = page => fetchDatasources(page);

onMounted(() => {
  if (!assistants.value.length) {
    store.dispatch('captainAssistants/get');
  }
  onPageChange(1);
});

</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.DOCUMENTS.HEADER')"
    :button-label="$t('CAPTAIN.DOCUMENTS.ADD_NEW')"
    :button-policy="['administrator']"
    :total-count="datasourcesMeta.totalCount"
    :current-page="datasourcesMeta.page"
    :show-pagination-footer="!isFetching && !!datasources.length"
    :is-fetching="isFetching"
    :is-empty="!datasources.length"
    :feature-flag="FEATURE_FLAGS.CAPTAIN"
    @update:current-page="onPageChange"
    @click="handleCreateDocument"
  >
    <template #emptyState>
      <DocumentPageEmptyState @click="handleCreateDocument" />
    </template>

    <template #paywall>
      <CaptainPaywall />
    </template>

    <template #controls>
    </template>

    <template #body>
      <LimitBanner class="mb-5" />

      <div class="flex flex-col gap-4">
        <DocumentCard
          v-for="doc in datasources"
          :id="doc.id"
          :key="doc.id"
          :name="doc.filename"
          :external-link="doc.externalLink"
          :created-at="doc.createdAt"
          :assistant="doc.assistant"
          :description="doc.description"
          :type="doc.type"
          :status="doc.status"
          @action="handleAction"
        />
      </div>
    </template>

    <RelatedResponses
      v-if="showRelatedResponses"
      ref="relationQuestionDialog"
      :captain-document="selectedDocument"
      @close="handleRelatedResponseClose"
    />
    <CreateDocumentDialog
      v-if="showCreateDialog"
      ref="createDocumentDialog"
      @close="handleCreateDialogClose"
      @created="fetchDatasources"
    />
    <DeleteDialog
      v-if="selectedDocument"
      ref="deleteDocumentDialog"
      :entity="selectedDocument"
      type="Documents"
      @delete-success="() => { selectedDocument.value = null; fetchDatasources(); }"
    />
    <Dialog
      v-if="showEditDialog"
      ref="editDocumentDialog"
      :title="$t('CAPTAIN.DOCUMENTS.OPTIONS.EDIT_DOCUMENT')"
      :show-cancel-button="false"
      :show-confirm-button="false"
      @close="handleEditDialogClose"
    >
      <DocumentForm
        v-if="editingDocument"
        :key="editingDocument.id"
        :initial-name="editingDocument.filename"
        :initial-description="editingDocument.description"
        :initial-type="editingDocument.type"
        :initial-url="editingDocument.url"
        :is-edit="true"
        @submit="handleEditSubmit"
        @cancel="handleEditDialogClose"
      />
    </Dialog>
  </PageLayout>
</template>
