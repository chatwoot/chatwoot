<script setup>
import { computed, onMounted, ref, toRef, watch, watchEffect } from 'vue';
import aiAgents from '../../../api/aiAgents';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import WootSubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';

const aiTemplates = ref()
async function fetchAiAgentTemplates() {
  aiTemplates.value = await aiAgents.listAiTemplate().then(v => v?.data)
}

const { accountId } = useAccount()

onMounted(() => {
  fetchAiAgents()
  fetchAiAgentTemplates()
})

const aiAgentsRef = ref()
const aiAgentsLoading = ref()
async function fetchAiAgents() {
  try {
    aiAgentsLoading.value = true

    const resp = await aiAgents.getAiAgents()
    aiAgentsRef.value = resp?.data
  } finally {
    aiAgentsLoading.value = false
  }
}

const loadingCards = ref({})
const dataToDelete = ref()
const showDeleteModal = ref()
async function deleteData() {
  showDeleteModal.value = false
  if (!dataToDelete.value) {
    return
  }

  const aiAgentId = dataToDelete.value.id
  try {
    loadingCards.value[aiAgentId] = true
    await aiAgents.removeAiAgent(aiAgentId)
    aiAgentsRef.value = aiAgentsRef.value?.filter(v => v.id !== aiAgentId)
  } finally {
    loadingCards.value[aiAgentId] = false
  }
}

// Create AI Agent modal
const showCreateAgentModal = ref(false)
const agentName = ref()
watch(showCreateAgentModal, v => {
  if (!v) {
    agentName.value = undefined
  }
})
const loadingCreate = ref(false)
async function createAiAgent() {
  const templateId = selectedTemplate.value
  const name = agentName.value?.trim()
  if (loadingCreate.value || !templateId || !name) {
    return
  }

  try {
    loadingCreate.value = true
    await aiAgents.createAiAgent(name, templateId)
    fetchAiAgents()
  } finally {
    loadingCreate.value = false
    showCreateAgentModal.value = false
  }
}

const templates = computed(() => aiTemplates.value?.map(e => ({
  label: e.name,
  id: `${e.id}`,
})))
const selectedTemplate = ref()
watchEffect(() => {
  if (templates.value && templates.value.length && !selectedTemplate.value) {
    selectedTemplate.value = templates.value[0].id
  }
})
</script>

<template>
  <div class="container mx-auto px-4 py-8">
    <div class="max-w-4xl mx-auto">
      <div class="text-center mb-12">
        <h1 class="text-4xl font-bold text-gray-900 dark:text-white mb-4">AI Agents</h1>
        <!-- <p class="text-lg text-gray-600 dark:text-gray-300">
          Deskripsi
        </p> -->
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div v-if="aiAgentsLoading" class="text-center">
          <span class="mt-4 mb-4 spinner" />
        </div>
        <div v-else v-for="agent in aiAgentsRef" :key="agent.id"
          class="group bg-white dark:bg-n-gray-3 rounded-2xl shadow-sm hover:shadow-lg transition-all duration-300 p-6 pb-3 flex flex-col">
          <div class="flex-1 flex items-center justify-center">
            <div v-if="loadingCards[agent.id]" class="text-center">
              <span class="mt-4 mb-4 spinner" />
            </div>
            <div v-else class="flex flex-col items-center justify-center gap-2">
              <h3
                class="text-xl font-semibold text-gray-900 dark:text-white transition-colors duration-300 text-center">
                {{ agent.name }}
              </h3>
              <p v-if="agent.description" class="text-gray-600 dark:text-gray-300 text-center">{{ agent.description }}
              </p>
            </div>
          </div>
          <div class="mt-2 pt-1 flex flex-wrap gap-2 items-center justify-center">
            <router-link :to="`/app/accounts/${accountId}/ai-agents/${agent.id}`">
              <button
                class="px-3 py-2 relative flex items-center justify-center rounded-lg text-slate-600 dark:text-slate-100 hover:bg-slate-25 dark:hover:bg-slate-700 dark:hover:text-slate-100 hover:text-slate-600">
                <span>Edit</span>
              </button>
            </router-link>
            <button
              class="px-3 py-2 relative flex items-center justify-center rounded-lg text-red-400 hover:bg-slate-25 dark:hover:bg-slate-700"
              @click="() => {
                dataToDelete = agent
                showDeleteModal = true
              }">
              <span>Delete</span>
            </button>
          </div>
        </div>
        <div
          class="group relative bg-white dark:bg-n-gray-3 rounded-2xl shadow-sm hover:shadow-lg transition-all duration-300 border-2 border-dashed border-gray-200 dark:border-gray-700 hover:border-primary-300 dark:hover:border-primary-400 p-6 cursor-pointer flex flex-col items-center justify-center min-h-[140px]"
          @click="() => showCreateAgentModal = true">
          <div class="text-center">
            <div
              class="w-14 h-14 bg-primary-200 dark:bg-gray-700 rounded-full flex items-center justify-center mx-auto mb-4 transition-colors duration-300">
              <span class="text-4xl text-white mb-[4px]">+</span>
            </div>
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Create New Agent</h3>
          </div>
        </div>
      </div>
    </div>
  </div>
  <woot-delete-modal v-if="showDeleteModal" v-model:show="showDeleteModal" class="context-menu--delete-modal" :on-close="() => {
    showDeleteModal = false
  }" :on-confirm="() => deleteData()" :title="'Are you sure you want to delete this AI Agent?'"
    :message="'You cannot undo this action'" :confirm-text="$t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.DELETE')"
    :reject-text="$t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.CANCEL')" />
  <!-- Add agent modal -->
  <woot-modal :show="showCreateAgentModal" :on-close="() => showCreateAgentModal = false">
    <woot-modal-header :header-title="'Create New AI Agent'" />
    <form @submit.prevent="() => createAiAgent()">
      <div class="flex flex-col">
        <div class="w-full">
          <label>
            Nama Agen AI
            <input v-model="agentName" type="text" :placeholder="'Nama Agen AI'" />
          </label>
        </div>

        <div class="w-full">
          <label>
            Template Agen
            <select v-model="selectedTemplate">
              <option v-for="template in templates" :key="template.id" :value="template.id">
                {{ template.label }}
              </option>
            </select>
          </label>
        </div>
      </div>

      <div class="flex items-center justify-start gap-2 pt-2">
        <WootSubmitButton :disabled="loadingCreate" :button-text="'Buat Agen AI'" :loading="loadingCreate"
          type="submit" />
      </div>
    </form>
  </woot-modal>
</template>