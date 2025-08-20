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

const agentTypes = [
  { label: 'Multi Agent', id: 'multi' },
  { label: 'Single Agent', id: 'single' },
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

const aiAgentsRef = ref();
const aiAgentsLoading = ref();
async function fetchAiAgents() {
  try {
    aiAgentsLoading.value = true;

    const resp = await aiAgents.getAiAgents();
    aiAgentsRef.value = resp?.data;
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
    await aiAgents.createAiAgent(name, templateIds);
    fetchAiAgents();
    showCreateAgentModal.value = false;
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
</script>

<template>
  <div class="w-full px-8 py-8 bg-n-background overflow-auto">
    <BaseSettingsHeader
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
      <table v-else class="divide-y divide-slate-75 dark:divide-slate-700">
        <tbody class="divide-y divide-n-weak text-n-slate-11">
          <tr v-for="(agent, _) in aiAgentsRef" :key="agent.id">
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <div class="flex flex-row items-center gap-4">
                <!-- <Thumbnail
                  :src="agent.thumbnail"
                  :username="agent.name"
                  size="40px"
                  :status="agent.availability_status"
                /> -->
                <div>
                  <span
                    class="block font-medium text-lg text-slate-900 dark:text-slate-25"
                  >
                    {{ agent.name }}
                  </span>
                  <span>{{ agent.description }}</span>
                </div>
              </div>
            </td>

            <td class="py-4">
              <div class="flex justify-end gap-1">
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
            </td>
          </tr>
        </tbody>
      </table>
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
          
          <!-- Custom: input for Flowise link -->
          <div v-else-if="selectedAgentType === 'custom'" class="w-full mb-1">
            <label>
              {{ $t('AGENT_MGMT.FORM_CREATE.CUSTOM_FLOW_LINK') }}
              <input
                v-model="state.customFlowLink"
                type="text"
                :placeholder="$t('AGENT_MGMT.FORM_CREATE.CUSTOM_FLOW_LINK')"
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
              class="w-full mb-[1rem] p-2 border rounded-md bg-white cursor-pointer flex items-center justify-between hover:border-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent min-h-[40px]"
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
              class="absolute z-10 w-full bottom-full mb-1 bg-white border border-gray-300 rounded-md shadow-lg max-h-48 overflow-y-auto"
            >
              <div
                v-for="template in templates"
                :key="template.id"
                @click="toggleTemplate(template.id)"
                class="flex items-center px-3 py-2 cursor-pointer hover:bg-gray-50"
                :class="{ 'bg-blue-50': isTemplateSelected(template.id) }"
              >
                <input
                  type="checkbox"
                  :checked="isTemplateSelected(template.id)"
                  class="mr-3 text-blue-600 rounded focus:ring-blue-500"
                  @click.stop
                >
                <span class="flex-1">{{ template.label }}</span>
                <svg
                  v-if="isTemplateSelected(template.id)"
                  class="w-4 h-4 text-blue-600"
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

      <div class="flex items-center justify-start gap-2 pt-2">
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
</style>