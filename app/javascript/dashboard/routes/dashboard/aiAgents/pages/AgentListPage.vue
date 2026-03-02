<script setup>
import { computed, ref, onMounted, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CreateAgentDialog from '../components/CreateAgentDialog.vue';
import AgentCard from '../components/AgentCard.vue';
import DeleteAgentDialog from '../components/DeleteAgentDialog.vue';

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const route = useRoute();

const createDialogRef = ref(null);
const deleteDialogRef = ref(null);
const dialogType = ref('');
const selectedAgent = ref(null);

const uiFlags = useMapGetter('aiAgents/getUIFlags');
const agents = useMapGetter('aiAgents/getAiAgents');

const isFetching = computed(() => uiFlags.value.isFetching);
const isEmpty = computed(() => !agents.value.length);

const handleCreate = () => {
  dialogType.value = 'create';
  selectedAgent.value = null;
  nextTick(() => createDialogRef.value?.dialogRef?.open());
};

const handleEdit = agent => {
  dialogType.value = 'edit';
  selectedAgent.value = agent;
  nextTick(() => createDialogRef.value?.dialogRef?.open());
};

const handleDelete = agent => {
  selectedAgent.value = agent;
  nextTick(() => deleteDialogRef.value?.dialogRef?.open());
};

const handleAfterCreate = newAgent => {
  if (newAgent?.id) {
    router.push({
      name: 'ai_agents_setup',
      params: {
        accountId: route.params.accountId,
        agentId: newAgent.id,
      },
    });
  }
};

const handleAfterDelete = () => {
  selectedAgent.value = null;
  useAlert(t('AI_AGENTS.DELETE.SUCCESS_MESSAGE'));
};

const handleDialogClose = () => {
  dialogType.value = '';
  selectedAgent.value = null;
};

const navigateToAgent = agent => {
  router.push({
    name: 'ai_agents_setup',
    params: {
      accountId: route.params.accountId,
      agentId: agent.id,
    },
  });
};

onMounted(() => {
  store.dispatch('aiAgents/get');
});
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <header class="sticky top-0 z-10 px-6">
      <div class="w-full max-w-5xl mx-auto">
        <div class="flex items-center justify-between w-full py-0 h-20 gap-2">
          <h1 class="text-xl font-medium text-n-slate-12">
            {{ t('AI_AGENTS.TITLE') }}
          </h1>
          <Button
            :label="t('AI_AGENTS.CREATE.TITLE')"
            icon="i-lucide-plus"
            size="sm"
            @click="handleCreate"
          />
        </div>
      </div>
    </header>

    <main class="flex-1 px-6 overflow-y-auto">
      <div class="w-full max-w-5xl h-full mx-auto py-4">
        <div
          v-if="isFetching"
          class="flex items-center justify-center py-10 text-n-slate-11"
        >
          <Spinner />
        </div>

        <div
          v-else-if="isEmpty"
          class="flex flex-col items-center justify-center py-20 gap-4"
        >
          <div class="i-lucide-bot size-12 text-n-slate-8" />
          <h3 class="text-lg font-medium text-n-slate-12">
            {{ t('AI_AGENTS.EMPTY.TITLE') }}
          </h3>
          <p class="text-sm text-n-slate-11 max-w-md text-center">
            {{ t('AI_AGENTS.EMPTY.DESCRIPTION') }}
          </p>
          <Button
            :label="t('AI_AGENTS.CREATE.TITLE')"
            icon="i-lucide-plus"
            @click="handleCreate"
          />
        </div>

        <div
          v-else
          class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
        >
          <AgentCard
            v-for="agent in agents"
            :key="agent.id"
            :agent="agent"
            @click="navigateToAgent(agent)"
            @edit="handleEdit(agent)"
            @delete="handleDelete(agent)"
          />
        </div>
      </div>
    </main>

    <CreateAgentDialog
      v-if="dialogType"
      ref="createDialogRef"
      :type="dialogType"
      :selected-agent="selectedAgent"
      @close="handleDialogClose"
      @created="handleAfterCreate"
    />

    <DeleteAgentDialog
      v-if="selectedAgent"
      ref="deleteDialogRef"
      :agent="selectedAgent"
      @close="handleDialogClose"
      @deleted="handleAfterDelete"
    />
  </section>
</template>
