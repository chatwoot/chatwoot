<script setup>
import { computed, onMounted, reactive, ref, watch, watchEffect } from 'vue';
import aiAgents from '../../../api/aiAgents';
import { useAccount } from 'dashboard/composables/useAccount';
import WootSubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';
import BaseSettingsHeader from '../settings/components/BaseSettingsHeader.vue';
import { useAlert } from 'dashboard/composables';
import { minLength, required } from '@vuelidate/validators';
import useVuelidate from '@vuelidate/core';
import { useI18n } from 'vue-i18n';

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
});
const rules = {
  agentName: { required, minLength: minLength(1) },
};
const v$ = useVuelidate(rules, state);
watch(showCreateAgentModal, v => {
  if (!v) {
    state.agentName = undefined;
  }
});
const loadingCreate = ref(false);
async function createAiAgent() {
  const valid = await v$.value.$validate();
  if (!valid) {
    return;
  }
  const templateId = selectedTemplate.value;
  const name = state.agentName?.trim();
  if (loadingCreate.value || !templateId || !name) {
    return;
  }

  try {
    loadingCreate.value = true;
    await aiAgents.createAiAgent(name, templateId);
    fetchAiAgents();
    showCreateAgentModal.value = false;
  } catch (e) {
    const errorMessage = error?.response?.data?.message;
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
const selectedTemplate = ref();
watchEffect(() => {
  if (templates.value && templates.value.length && !selectedTemplate.value) {
    selectedTemplate.value = templates.value[0].id;
  }
});
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

        <div class="w-full">
          <label>
            {{ $t('AGENT_MGMT.FORM_CREATE.AI_AGENT_TEMPLATE') }}
            <select v-model="selectedTemplate">
              <option
                v-for="template in templates"
                :key="template.id"
                :value="template.id"
              >
                {{ template.label }}
              </option>
            </select>
          </label>
        </div>
      </div>

      <div class="flex items-center justify-start gap-2 pt-2">
        <WootSubmitButton
          :disabled="loadingCreate || v$.$invalid"
          :button-text="$t('AI_AGENTS.CREATE_NEW')"
          :loading="loadingCreate"
          type="submit"
        />
      </div>
    </form>
  </woot-modal>
</template>
