<script setup>
import { computed, onMounted, reactive, ref, watch, watchEffect } from 'vue';
import InputRadioGroup from 'dashboard/routes/dashboard/settings/inbox/components/InputRadioGroup.vue';
import aiAgents from '../../../api/aiAgents';
import { useAccount } from 'dashboard/composables/useAccount';
import WootSubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';
import BaseSettingsHeader from '../settings/components/BaseSettingsHeader.vue';
import { useAlert } from 'dashboard/composables';
import { minLength, required } from '@vuelidate/validators';
import useVuelidate from '@vuelidate/core';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';

const agentTypes = [
  { label: 'Single Agent', id: 'single' },
  { label: 'Multi Agent', id: 'multi' },
  { label: 'Custom Agent', id: 'custom' }
];
const selectedAgentType = ref(agentTypes[0].id);

function handleAgentTypeChange(item) {
  selectedAgentType.value = item.id;
}

const aiTemplates = ref();
async function fetchAiAgentTemplates() {
  aiTemplates.value = await aiAgents.listAiTemplate().then(v => v?.data);
  }

const { accountId } = useAccount();
const { t } = useI18n()

onMounted(() => {
  fetchAiAgents();
  fetchAiAgentTemplates();
});

const router = useRouter();
const aiAgentsRef = ref();
const aiAgentsLoading = ref();
async function fetchAiAgents() {
  try {
    aiAgentsLoading.value = true;

    const resp = await aiAgents.getAiAgents();
    aiAgentsRef.value = resp?.data;
    
    // Fetch additional details for each agent (description and type)
    if (aiAgentsRef.value && aiAgentsRef.value.length) {
      await Promise.all(
        aiAgentsRef.value.map(async (agent) => {
          try {
            const detailResp = await aiAgents.detailAgent(agent.id);
            const agentData = detailResp?.data;
            
            // Get type from display_flow_data.type (multi_agent or single_agent)
            if (agentData?.display_flow_data?.type) {
              agent.type = agentData.display_flow_data.type;
            }
            
            // Get enabled agents list
            if (agentData?.display_flow_data?.enabled_agents) {
              agent.enabled_agents = agentData.display_flow_data.enabled_agents;
            }
            
            // Get description/instructions from agents_config
            if (agentData?.display_flow_data?.agents_config?.[0]?.bot_prompt?.instructions) {
              agent.description = agentData.display_flow_data.agents_config[0].bot_prompt.instructions;
            }
          } catch (err) {
            console.error(`Failed to fetch details for agent ${agent.id}:`, err);
          }
        })
      );
    }
    
    console.log('Fetched AI Agents:', aiAgentsRef.value);
  } finally {
    aiAgentsLoading.value = false;
  }
}

const loadingCards = ref({});
const dataToDelete = ref();
const showDeleteModal = ref();
async function deleteData() {
  showDeleteModal.value = false;
  if (!dataToDelete.value) {
    return;
  }

  const aiAgentId = dataToDelete.value.id;
  try {
    loadingCards.value[aiAgentId] = true;
    await aiAgents.removeAiAgent(aiAgentId);
    aiAgentsRef.value = aiAgentsRef.value?.filter(v => v.id !== aiAgentId);
  } finally {
    loadingCards.value[aiAgentId] = false;
  }
}

// Create AI Agent modal
const showCreateAgentModal = ref(false);
const state = reactive({
  agentName: '',
  selectedTemplate: '',
  customFlowLink: '',
  selectedTemplates: [],
});
const rules = computed(() => ({
  agentName: { required, minLength: minLength(1) },
  ...(selectedAgentType.value === 'multi'
    ? { selectedTemplates: { required: (value) => value && value.length > 0 } }
    : selectedAgentType.value === 'custom'
    ? { customFlowLink: { required, minLength: minLength(1) } }
    : { selectedTemplate: { required } }
  )
}));
const v$ = useVuelidate(rules, state);
watch(showCreateAgentModal, v => {
  if (!v) {
    state.agentName = '';
    state.selectedTemplate = '';
    state.customFlowLink = '';
    state.selectedTemplates = [];
    selectedAgentType.value = agentTypes[0].id; // Reset to first option
  }
});
const loadingCreate = ref(false);
async function createAiAgent() {
  const valid = await v$.value.$validate();
  if (!valid) {
    return;
  }
  
  const name = state.agentName?.trim();
  let templateIds;
  
  if (selectedAgentType.value === 'multi') {
    templateIds = state.selectedTemplates;
    if (loadingCreate.value || !templateIds?.length || !name) {
      return;
    }
  } else if (selectedAgentType.value === 'custom') {
    templateIds = state.customFlowLink;
    if (loadingCreate.value || !templateIds || !name) {
      return;
    }
  } else {
    templateIds = state.selectedTemplate;
    if (loadingCreate.value || !templateIds || !name) {
      return;
    }
  }

  try {
  loadingCreate.value = true;
  const resp = await aiAgents.createAiAgent(name, templateIds);
  const newAgentId = resp?.data?.id;
  showCreateAgentModal.value = false;
  if (newAgentId) {
    const accountIdValue = accountId?.value || accountId;
    router.push(`/app/accounts/${accountIdValue}/ai-agents/${newAgentId}`);
  } else {
    console.log('No agent ID found, fetching agents list');
    fetchAiAgents();
  }
  } catch (e) {
  const errorMessage = e?.response?.data?.error;
  useAlert(errorMessage || t('AGENT_MGMT.FORM_CREATE.FAILED_ADD'));  
  } finally {
    loadingCreate.value = false;
  }
}

const templates = computed(() =>
  aiTemplates.value?.map(e => ({
    label: e.name,
    id: `${e.id}`,
    description: e.description,
  }))
);
const selectedTemplate = computed({
  get: () => state.selectedTemplate,
  set: (value) => { state.selectedTemplate = value; }
});
const selectedTemplates = computed({
  get: () => state.selectedTemplates,
  set: (value) => { state.selectedTemplates = value; }
});

const selectedTemplateDescription = computed(() => {
  return templates.value?.find(t => t.id === selectedTemplate.value)?.description || '';
});

// Multi-select dropdown state
const isDropdownOpen = ref(false);
const dropdownRef = ref(null);

// Toggle template selection for multi-select
function toggleTemplate(templateId) {
  const index = selectedTemplates.value.indexOf(templateId);
  if (index > -1) {
    selectedTemplates.value.splice(index, 1);
  } else {
    selectedTemplates.value.push(templateId);
  }
}

function isTemplateSelected(templateId) {
  return selectedTemplates.value.includes(templateId);
}

const selectedTemplateLabels = computed(() => {
  if (!selectedTemplates.value.length) return '';
  return templates.value
    ?.filter(t => selectedTemplates.value.includes(t.id))
    .map(t => t.label)
    .join(', ');
});

function handleClickOutside(event) {
  if (dropdownRef.value && !dropdownRef.value.contains(event.target)) {
    isDropdownOpen.value = false;
  }
}

watch(isDropdownOpen, (isOpen) => {
  if (isOpen) {
    document.addEventListener('click', handleClickOutside);
  } else {
    document.removeEventListener('click', handleClickOutside);
  }
});


// Watch for agent type changes to reset template selection
watch(selectedAgentType, (newType) => {
  state.selectedTemplates = [];
  state.customFlowLink = '';
  if (newType === 'multi') {
    state.selectedTemplate = '';
  } else if (newType === 'custom') {
    state.selectedTemplate = '';
  } else {
    // For single agent, set default template
    if (templates.value && templates.value.length) {
      setDefaultTemplate();
    } else {
      state.selectedTemplate = '';
    }
  }
});

watch(aiTemplates, (v) => {
  if ((selectedAgentType.value === 'single') && templates.value?.length) {
    setDefaultTemplate();
  }
});

// pick a default template for single
function setDefaultTemplate() {
  if (!templates.value || !templates.value.length) {
    state.selectedTemplate = '';
    return;
  }

  state.selectedTemplate = templates.value[0].id;
}

// ini copy dari fluenticon
function getAgentIcon(agent) {
  const iconMap = {
    customer_service: `
      <svg width="24" height="24" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M5 9a7 7 0 0 1 14 0v5a2 2 0 0 1-2 2h-2a1 1 0 0 1-1-1v-4a1 1 0 0 1 1-1h2.5V9a5.5 5.5 0 1 0-11 0v1H9a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1H7c-.173 0-.34-.022-.5-.063v.313a2.25 2.25 0 0 0 2.096 2.245l.154.005h1.128a2.251 2.251 0 1 1 0 1.5H8.75a3.75 3.75 0 0 1-3.745-3.55L5 16.25V9Z" fill="currentColor"/></svg>
    `,
    sales: `
      <svg width="24" height="24" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2Zm2.492 7.36a.75.75 0 1 1-1.484-.22c.162-1.09 1.123-1.89 2.242-1.89s2.08.8 2.242 1.89a.75.75 0 1 1-1.484.22c-.048-.323-.35-.61-.758-.61-.408 0-.71.287-.758.61ZM12 18c-3.142 0-5.237-2.363-5.5-5.25h11C17.237 15.637 15.142 18 12 18ZM8.75 8.75c-.408 0-.71.287-.758.61a.75.75 0 1 1-1.484-.22C6.67 8.05 7.631 7.25 8.75 7.25s2.08.8 2.242 1.89a.75.75 0 1 1-1.484.22c-.048-.323-.35-.61-.758-.61Z" fill="currentColor"/></svg>
    `,
    booking: `
      <svg width="24" height="24" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M6.5 2A2.5 2.5 0 0 0 4 4.5v15A2.5 2.5 0 0 0 6.5 22h13.25a.75.75 0 0 0 0-1.5H6.5a1 1 0 0 1-1-1h14.25a.75.75 0 0 0 .75-.75V4.5A2.5 2.5 0 0 0 18 2H6.5ZM8 5h8a1 1 0 0 1 1 1v1a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1Z" fill="currentColor"/></svg>
    `,
    restaurant: `
      <svg width="24" height="24" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M18 3a1 1 0 0 1 .993.883L19 4v16a1 1 0 0 1-1.993.117L17 20v-5h-1a1 1 0 0 1-.993-.883L15 14V8c0-2.21 1.5-5 3-5Zm-6 0a1 1 0 0 1 .993.883L13 4v5a4.002 4.002 0 0 1-3 3.874V20a1 1 0 0 1-1.993.117L8 20v-7.126a4.002 4.002 0 0 1-2.995-3.668L5 9V4a1 1 0 0 1 1.993-.117L7 4v5a2 2 0 0 0 1 1.732V4a1 1 0 0 1 1.993-.117L10 4l.001 6.732a2 2 0 0 0 .992-1.563L11 9V4a1 1 0 0 1 1-1Z" fill="currentColor"/></svg>
    `,
    custom_agent: `
      <svg width="24" height="24" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="m8.086 18.611 5.996-14.004a1 1 0 0 1 1.878.677l-.04.11-5.996 14.004a1 1 0 0 1-1.878-.677l.04-.11 5.996-14.004L8.086 18.61Zm-5.793-7.318 4-4a1 1 0 0 1 1.497 1.32l-.083.094L4.414 12l3.293 3.293a1 1 0 0 1-1.32 1.498l-.094-.084-4-4a1 1 0 0 1-.083-1.32l.083-.094 4-4-4 4Zm14-4.001a1 1 0 0 1 1.32-.083l.093.083 4.001 4.001a1 1 0 0 1 .083 1.32l-.083.095-4.001 3.995a1 1 0 0 1-1.497-1.32l.084-.095L19.584 12l-3.293-3.294a1 1 0 0 1 0-1.414Z" fill="currentColor"/></svg>
    `,
    lead_generation: `
      <svg width="24" height="24" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M16.25 2a.75.75 0 0 1 .743.648L17 2.75v.749h.749a2.25 2.25 0 0 1 2.25 2.25V16h-3.754l-.154.005a2.25 2.25 0 0 0-2.09 2.084l-.006.161v3.755H5.754a2.25 2.25 0 0 1-2.25-2.25L3.502 5.75a2.25 2.25 0 0 1 2.25-2.25l.747-.001.001-.749a.75.75 0 0 1 1.493-.102L8 2.75v.749H11V2.75a.75.75 0 0 1 1.494-.102l.007.102v.749h2.997l.001-.749a.75.75 0 0 1 .75-.75Zm3.31 15.5-4.066 4.065.001-3.315.007-.102a.75.75 0 0 1 .641-.641l.102-.007h3.314ZM11.247 16H7.25l-.102.007a.75.75 0 0 0 0 1.486l.102.007h3.998l.102-.007a.75.75 0 0 0 0-1.486L11.248 16Zm5-4H7.25l-.102.007a.75.75 0 0 0 0 1.486l.102.007h8.998l.102-.007a.75.75 0 0 0 0-1.486L16.248 12Zm0-4H7.25l-.102.007a.75.75 0 0 0 0 1.486l.102.007h8.998l.102-.007a.75.75 0 0 0 0-1.486L16.248 8Z" fill="currentColor"/></svg>
    `,

    // Add other agent types here...
  };

  // For multi-agent, use a specific SVG
  if (agent.type === 'multi_agent') {
    return `
      <svg width="24" height="24" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M14.754 10c.966 0 1.75.784 1.75 1.75v4.749a4.501 4.501 0 0 1-9.002 0V11.75c0-.966.783-1.75 1.75-1.75h5.502Zm-7.623 0c-.35.422-.575.95-.62 1.53l-.01.22v4.749c0 .847.192 1.649.534 2.365A4.001 4.001 0 0 1 2 14.999V11.75a1.75 1.75 0 0 1 1.606-1.744L3.75 10h3.381Zm9.744 0h3.375c.966 0 1.75.784 1.75 1.75V15a4 4 0 0 1-5.03 3.866c.3-.628.484-1.32.525-2.052l.009-.315V11.75c0-.665-.236-1.275-.63-1.75ZM12 3a3 3 0 1 1 0 6 3 3 0 0 1 0-6Zm6.5 1a2.5 2.5 0 1 1 0 5 2.5 2.5 0 0 1 0-5Zm-13 0a2.5 2.5 0 1 1 0 5 2.5 2.5 0 0 1 0-5Z" fill="currentColor"/></svg>
    `;
  }

  // For single agent, get the SVG from the first enabled agent type
  if (agent.enabled_agents && agent.enabled_agents.length > 0) {
    return iconMap[agent.enabled_agents[0]] || iconMap.technical_support;
  }

  return iconMap.technical_support; // Default icon
}

// Get formatted agent type label
function getAgentTypeLabel(agent) {
  if (agent.type === 'multi_agent' && agent.enabled_agents) {
    return agent.enabled_agents.map(type => type.replace(/_/g, ' ')).join(', ');
  }
  
  if (agent.enabled_agents && agent.enabled_agents.length > 0) {
    return agent.enabled_agents[0].replace(/_/g, ' ');
  }
  
  return agent.type?.replace(/_/g, ' ') || 'Agent';
}


</script>

<template>
  <div class="w-full px-8 py-8 bg-n-background overflow-auto">
    <BaseSettingsHeader
      class="pb-4"
      :title="$t('SIDEBAR.AI_AGENTS')"
      :description="$t('SIDEBAR.AI_AGENTS_DESC')"
    >
      <template #actions>
        <woot-button
          class="rounded-md button nice"
          icon="add-circle"
          @click="() => (showCreateAgentModal = true)"
        >
          {{ $t('AI_AGENTS.CREATE_NEW') }}
        </woot-button>
      </template>
    </BaseSettingsHeader>
    <div>
      <div v-if="aiAgentsLoading" class="text-center">
        <span class="mt-4 mb-4 spinner" />
      </div>
      <div v-else-if="!aiAgentsRef || !aiAgentsRef.length">
        <span>{{ $t('AGENT_MGMT.FORM_CREATE.EMPTY_AI_AGENT') }}</span>
      </div>
      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="agent in aiAgentsRef"
          :key="agent.id"
          class="bg-white dark:bg-slate-800 rounded-lg shadow-md hover:shadow-lg transition-shadow duration-200 overflow-hidden border border-slate-200 dark:border-slate-700"
        >
          <!-- Card Header with Icon -->
          <div class="p-6 py-4 flex items-center gap-4">
            <div class="flex-shrink-0">
              <div class="w-12 h-12 rounded-full bg-white dark:bg-slate-700 flex items-center justify-center shadow-sm border border-slate-200 dark:border-slate-700">
                <div v-html="getAgentIcon(agent)" class="text-slate-700 dark:text-slate-200"></div>
              </div>
            </div>
            <div class="flex-1 min-w-0">
              <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-25 truncate">
                {{ agent.name }}
              </h3>
              <p class="text-xs text-slate-600 dark:text-slate-400 capitalize">
                {{ getAgentTypeLabel(agent) }}
              </p>
            </div>
          </div>

          <!-- Card Body -->
          <div class="p-6 pt-0 py-4">
            <p class="text-sm text-slate-600 dark:text-slate-400 line-clamp-3 min-h-[60px]">
              {{ agent.description || 'Tidak ada deskripsi' }}
            </p>
          </div>

          <!-- Card Footer with Actions -->
          <div class="px-6 pb-6 flex justify-end gap-2 border-t border-slate-100 dark:border-slate-700 pt-4">
            <RouterLink
              :to="`/app/accounts/${accountId}/ai-agents/${agent.id}`"
            >
              <woot-button
                v-tooltip.top="$t('AGENT_MGMT.EDIT.BUTTON_TEXT')"
                variant="smooth"
                color-scheme="secondary"
                icon="edit"
                class-names="grey-btn"
              />
            </RouterLink>
            <woot-button
              v-tooltip.top="$t('AGENT_MGMT.DELETE.BUTTON_TEXT')"
              variant="smooth"
              color-scheme="alert"
              icon="dismiss-circle"
              class-names="grey-btn"
              :is-loading="loadingCards[agent.id]"
              @click="
                () => {
                  dataToDelete = agent;
                  showDeleteModal = true;
                }
              "
            />
          </div>
        </div>
      </div>
    </div>
  </div>
  <woot-delete-modal
    v-if="showDeleteModal"
    v-model:show="showDeleteModal"
    class="context-menu--delete-modal"
    :on-close="
      () => {
        showDeleteModal = false;
      }
    "
    :on-confirm="() => deleteData()"
    title="Apakah kamu akan menghapus data ini?"
    message="You cannot undo this action"
    :confirm-text="$t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.DELETE')"
    :reject-text="$t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.CANCEL')"
  />
  <!-- Add agent modal -->
  <woot-modal
    :show="showCreateAgentModal"
    :on-close="() => (showCreateAgentModal = false)"
  >
    <woot-modal-header :header-title="$t('AI_AGENTS.CREATE_NEW')" />
    <form @submit.prevent="() => createAiAgent()">
      <div class="flex flex-col">
        <div class="w-full mb-2">
          <label>
            {{ $t('AGENT_MGMT.FORM_CREATE.AI_AGENT_NAME') }}
            <input
              v-model="state.agentName"
              type="text"
              class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
              :placeholder="$t('AGENT_MGMT.FORM_CREATE.AI_AGENT_NAME')"
              style="margin-bottom: 0px"
            />
          </label>
          <div
            v-for="error of v$.agentName.$errors"
            :key="error.$uid"
            class="input-errors"
          >
            <div class="text-red-500">{{ error.$message }}</div>
          </div>
        </div>

        <div class="w-full mb-2">
          <label class="block mb-1">
            {{ $t('AGENT_MGMT.FORM_CREATE.AI_AGENT_TYPE') }}
          </label>
          <div class="flex gap-4">
            <label
              v-for="type in agentTypes"
              :key="type.id"
              class="flex items-center gap-2"
            >
              <input
                type="radio"
                :value="type.id"
                v-model="selectedAgentType"
                name="agentType"
              />
              {{ type.label }}
            </label>
          </div>
        </div>

        <div class="w-full">
          <label class="block mb-1" v-if="selectedAgentType === 'single' || selectedAgentType === 'multi'">
            {{ $t('AGENT_MGMT.FORM_CREATE.AI_AGENT_TEMPLATE') }}
          </label>
          
          <!-- Single select for single -->
          <select 
            v-if="selectedAgentType === 'single'" 
            v-model="selectedTemplate"
            class="w-full p-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            :class="{ 'border-red-500': v$.selectedTemplate.$error }"
          >
            <option v-if="!selectedTemplate" class="text-gray-500" value="">Select a template...</option>
            <option
              v-for="template in templates"
              :key="template.id"
              :value="template.id"
            >
              {{ template.label }}
            </option>
          </select>
          <div v-if="selectedAgentType === 'single' && selectedTemplateDescription" class="text-xs text-gray-500 mt-1 mb-2">
            {{ selectedTemplateDescription }}
          </div>
          
          <!-- Custom: input for Flowise link -->
          <div v-else-if="selectedAgentType === 'custom'" class="w-full mb-1">
            <label>
              {{ $t('AGENT_MGMT.FORM_CREATE.CUSTOM_FLOW_LINK') }}
              <input
                v-model="state.customFlowLink"
                type="text"
                :placeholder="$t('AGENT_MGMT.FORM_CREATE.CUSTOM_FLOW_LINK_PLACEHOLDER')"
                style="margin-bottom: 0px"
              />
            </label>
            <div
              v-for="error of v$.customFlowLink.$errors"
              :key="error.$uid"
              class="input-errors"
            >
              <div class="text-red-500">{{ error.$message }}</div>
            </div>
          </div>
          
          <!-- Error message for single select -->
          <div
            v-if="selectedAgentType === 'single' && v$.selectedTemplate.$error"
            class="mt-1"
          >
            <div
              v-for="error of v$.selectedTemplate.$errors"
              :key="error.$uid"
              class="text-red-500 text-sm"
            >
              {{ error.$message }}
            </div>
          </div>
          
          <!-- Custom multi-select dropdown for multi agent -->
          <div v-else-if="selectedAgentType === 'multi'" class="relative" ref="dropdownRef">
            <div
              @click="isDropdownOpen = !isDropdownOpen"
              class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-auto !px-3 !py-2.5 !mb-4 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out cursor-pointer flex items-center justify-between min-h-[40px]"
              :class="{ 
                'border-red-500': v$.selectedTemplates.$error,
                'border-gray-300': !v$.selectedTemplates.$error 
              }"
            >
              <div class="flex-1 text-left">
                <span v-if="selectedTemplates.length === 0" class="text-gray-500">
                  {{ $t('AGENT_MGMT.FORM_CREATE.SELECT_TEMPLATES') }}
                </span>
                <div v-else class="flex flex-wrap gap-1">
                  <span
                    v-for="templateId in selectedTemplates"
                    :key="templateId"
                    class="inline-flex items-center px-2 py-1 text-xs font-medium bg-green-100 text-green-800 rounded-full"
                  >
                    {{ templates?.find(t => t.id === templateId)?.label }}
                    <button
                      type="button"
                      @click.stop="toggleTemplate(templateId)"
                      class="ml-1 hover:text-green-600"
                    >
                      <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                        <path
                          d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z"
                        />
                      </svg>
                    </button>
                  </span>
                </div>
              </div>
              <svg
                class="w-5 h-5 text-gray-400 transition-transform"
                :class="{ 'rotate-180': isDropdownOpen }"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
              </svg>
            </div>
            
            <!-- Dropdown options -->
            <div
              v-show="isDropdownOpen"
              class="absolute z-10 w-full top-full mt-1 bg-white dark:bg-slate-800 border border-gray-300 dark:border-gray-600 rounded-md shadow-lg max-h-48 overflow-y-auto"
            >
              <div
                v-for="template in templates"
                :key="template.id"
                @click="toggleTemplate(template.id)"
                class="flex items-center px-3 py-2 text-sm cursor-pointer hover:bg-gray-50 dark:hover:bg-slate-700 text-gray-900 dark:text-gray-100 transition-colors duration-150"
                :class="{ 
                  'bg-blue-50 dark:bg-blue-900/50 text-blue-900 dark:text-blue-100': isTemplateSelected(template.id),
                  'hover:bg-gray-50 dark:hover:bg-slate-700': !isTemplateSelected(template.id)
                }"
              >
                <input
                  type="checkbox"
                  :checked="isTemplateSelected(template.id)"
                  class="mr-3 text-blue-600 dark:text-blue-400 bg-gray-100 dark:bg-gray-700 border-gray-300 dark:border-gray-600 rounded focus:ring-blue-500 dark:focus:ring-blue-400"
                  @click.stop
                >
                <span class="flex-1 text-sm">{{ template.label }}
                  <span v-if="template.description" class="block text-xs text-gray-500 dark:text-gray-400">
                    {{ template.description }}
                  </span>
                </span>
                <svg
                  v-if="isTemplateSelected(template.id)"
                  class="w-4 h-4 text-blue-600 dark:text-blue-400"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" />
                </svg>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="flex items-center justify-start gap-2 pt-2 pb-4">
        <WootSubmitButton
          :disabled="loadingCreate"
          :button-text="$t('AI_AGENTS.CREATE_NEW')"
          :loading="loadingCreate"
          type="submit"
        />
      </div>
    </form>
  </woot-modal>
</template>

<style scoped>
/* Additional styles for better UX */
.rotate-180 {
  transform: rotate(180deg);
}

.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>