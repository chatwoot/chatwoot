<script setup>
import { reactive, computed, watch, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';
import Auth from 'dashboard/api/auth';
import { useAccount } from 'dashboard/composables/useAccount';
import { getAgentManagerBaseUrl } from 'dashboard/constants/agentManager';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
// import { toolsList } from 'dashboard/constants/tools';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['edit', 'create'].includes(value),
  },
  assistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();
const { accountId } = useAccount();

const formState = {
  uiFlags: useMapGetter('captainAssistants/getUIFlags'),
};

const initialState = {
  name: '',
  description: '',
  tools: [],
  documents: [], // Add documents to form state
};

const state = reactive({ ...initialState });

// --- TOOLS FETCH LOGIC ---
const tools = ref([]);
const isFetchingTools = ref(false);
const fetchTools = async () => {
  isFetchingTools.value = true;
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
    const response = await fetch(`${baseUrl}/agent-manager/api/v1/tools?page=1`, {
      method: 'GET',
      headers,
    });
    if (!response.ok) {
      throw new Error(`API request failed: ${response.status} ${response.statusText}`);
    }
    const result = await response.json();
    tools.value = (result.data || []).filter(tool => tool.is_integrated !== false && tool.enabled !== false);
  } catch (error) {
    tools.value = [];
  } finally {
    isFetchingTools.value = false;
  }
};
onMounted(fetchTools);
// --- END TOOLS FETCH LOGIC ---

// --- DOCUMENTS FETCH LOGIC (copied from fetchDatasources in documents/Index.vue) ---
const documents = ref([]);
const isFetchingDocuments = ref(false);
const fetchDocuments = async (page = 1) => {
  isFetchingDocuments.value = true;
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
    documents.value = dataArray.map(ds => {
      return {
        id: ds.id,
        name: ds.name || ds.filename || 'Untitled Document',
        description: ds.description || '',
        type: ds.type || (ds.web_url ? 'web_url' : ''),
        externalLink: ds.documents && ds.documents[0] ? ds.documents[0].name : (ds.web_url || ''),
      };
    });
  } catch (error) {
    documents.value = [];
  } finally {
    isFetchingDocuments.value = false;
  }
};
onMounted(() => {
  fetchTools();
  fetchDocuments();
});
// --- END DOCUMENTS FETCH LOGIC ---

const availableTools = computed(() => tools.value);
const availableDocuments = computed(() => documents.value);

const validationRules = {
  name: { required, minLength: minLength(1) },
  description: { required, minLength: minLength(1) }
};

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error && v$.value[field].$dirty && v$.value[field].$touched
    ? t(`CAPTAIN.ASSISTANTS.FORM.${errorKey}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  name: getErrorMessage('name', 'NAME'),
  description: getErrorMessage('description', 'DESCRIPTION')
}));

const handleCancel = () => emit('cancel');

const prepareAssistantDetails = () => ({
  name: state.name,
  description: state.description,
  tools: state.tools,
  datasources: state.documents, // Send the full document objects to the backend
  model: "gpt-4o-mini", //currently set this by default
});

const handleSubmit = async () => {
  v$.value.$touch();
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }

  emit('submit', prepareAssistantDetails());
};

const updateStateFromAssistant = assistant => {
  if (!assistant) return;

  // Support both possible field names for robustness
  const name = assistant.title || assistant.name || '';
  const description = assistant.guidance || assistant.description || '';
  const tools = assistant.tools ?? [];
  const datasources = assistant.datasources ?? [];

  // Map datasources to the correct structure for the MultiselectDropdown
  const mappedDocuments = datasources.map(ds => {
    // If datasource is already an object with id and name, use it as is
    if (typeof ds === 'object' && ds.id && ds.name) {
      return ds;
    }
    // If datasource is just an ID, find the corresponding document from availableDocuments
    if (typeof ds === 'number' || typeof ds === 'string') {
      const foundDoc = documents.value.find(doc => doc.id == ds);
      return foundDoc || { id: ds, name: `Document ${ds}` };
    }
    // If it's an object but missing required fields, try to construct it
    if (typeof ds === 'object') {
      return {
        id: ds.id || ds.datasource_id || ds,
        name: ds.name || ds.filename || `Document ${ds.id || ds.datasource_id || ds}`,
        description: ds.description || '',
        type: ds.type || '',
        externalLink: ds.externalLink || ds.web_url || ''
      };
    }
    return { id: ds, name: `Document ${ds}` };
  });

  Object.assign(state, {
    name,
    description,
    tools,
    documents: mappedDocuments,
  });
};

watch(
  () => props.assistant,
  newAssistant => {
    if (props.mode === 'edit' && newAssistant) {
      updateStateFromAssistant(newAssistant);
    }
  },
  { immediate: true }
);
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <Input
      v-model="state.name"
      :label="t('CAPTAIN.ASSISTANTS.FORM.NAME.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.NAME.PLACEHOLDER')"
      :message="formErrors.name"
      :message-type="formErrors.name ? 'error' : 'info'"
    />

    <Editor
      v-model="state.description"
      :label="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.PLACEHOLDER')"
      :message="formErrors.description"
      :message-type="formErrors.description ? 'error' : 'info'"
      :max-length="20000"
    />

    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.TOOLS.HEADER') }}
      </label>
      <MultiselectDropdown
        v-model="state.tools"
        :options="availableTools"
        :multiple="true"
        :searchable="true"
        :close-on-select="false"
        :clear-on-select="false"
        :multiselector-placeholder="$t('CAPTAIN.ASSISTANTS.FORM.TOOLS.PLACEHOLDER')"
        :has-thumbnail="false"
        :has-checkbox="true"
        label="name"
        track-by="id"
        :preselect-first="false"
        :loading="isFetchingTools"
      />
    </div>

    <!-- Documents Multiselect Dropdown -->
    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.ASSISTANTS.FORM.DOCUMENTS.TITLE') }}
      </label>
      <MultiselectDropdown
        v-model="state.documents"
        :options="availableDocuments"
        :multiple="true"
        :searchable="true"
        :close-on-select="false"
        :clear-on-select="false"
        :multiselector-placeholder="$t('CAPTAIN.ASSISTANTS.FORM.DOCUMENTS.PLACEHOLDER')"
        :has-thumbnail="false"
        :has-checkbox="true"
        label="name"
        track-by="id"
        :preselect-first="false"
        :loading="isFetchingDocuments"
      />
    </div>

    <div class="flex items-center justify-between w-full gap-3">
      <Button
        type="button"
        variant="faded"
        color="slate"
        :label="t('CAPTAIN.FORM.CANCEL')"
        class="w-full bg-n-alpha-2 n-blue-text hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        type="submit"
        :label="mode === 'edit' ? t('CAPTAIN.FORM.EDIT') : t('CAPTAIN.FORM.CREATE')"
        class="w-full"
        :is-loading="isLoading"
        :disabled="isLoading"
      />
    </div>
  </form>
</template>
