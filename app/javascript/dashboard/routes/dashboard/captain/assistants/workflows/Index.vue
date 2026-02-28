<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import SettingsHeader from 'dashboard/components-next/captain/pageComponents/settings/SettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();

const assistantId = computed(() => Number(route.params.assistantId));
const uiFlags = useMapGetter('captainWorkflows/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingList);
const workflows = useMapGetter('captainWorkflows/getRecords');

const TRIGGER_LABELS = {
  conversation_created:
    'CAPTAIN.ASSISTANTS.WORKFLOWS.TRIGGERS.CONVERSATION_CREATED',
  message_created: 'CAPTAIN.ASSISTANTS.WORKFLOWS.TRIGGERS.MESSAGE_CREATED',
  conversation_resolved:
    'CAPTAIN.ASSISTANTS.WORKFLOWS.TRIGGERS.CONVERSATION_RESOLVED',
};

const createWorkflow = async () => {
  try {
    const workflow = await store.dispatch('captainWorkflows/create', {
      assistantId: assistantId.value,
      name: t('CAPTAIN.ASSISTANTS.WORKFLOWS.DEFAULT_NAME'),
      trigger_event: 'conversation_created',
      nodes: [],
      edges: [],
    });
    router.push({
      name: 'captain_assistants_workflow_editor',
      params: {
        accountId: route.params.accountId,
        assistantId: assistantId.value,
        workflowId: workflow.id,
      },
    });
  } catch (error) {
    useAlert(
      error?.response?.message ||
        t('CAPTAIN.ASSISTANTS.WORKFLOWS.API.CREATE.ERROR')
    );
  }
};

const editWorkflow = workflowId => {
  router.push({
    name: 'captain_assistants_workflow_editor',
    params: {
      accountId: route.params.accountId,
      assistantId: assistantId.value,
      workflowId,
    },
  });
};

const toggleWorkflow = async workflow => {
  try {
    await store.dispatch('captainWorkflows/update', {
      id: workflow.id,
      assistantId: assistantId.value,
      enabled: !workflow.enabled,
    });
    useAlert(t('CAPTAIN.ASSISTANTS.WORKFLOWS.API.UPDATE.SUCCESS'));
  } catch (error) {
    useAlert(
      error?.response?.message ||
        t('CAPTAIN.ASSISTANTS.WORKFLOWS.API.UPDATE.ERROR')
    );
  }
};

const deleteWorkflow = async id => {
  try {
    await store.dispatch('captainWorkflows/delete', {
      id,
      assistantId: assistantId.value,
    });
    useAlert(t('CAPTAIN.ASSISTANTS.WORKFLOWS.API.DELETE.SUCCESS'));
  } catch (error) {
    useAlert(
      error?.response?.message ||
        t('CAPTAIN.ASSISTANTS.WORKFLOWS.API.DELETE.ERROR')
    );
  }
};

onMounted(() => {
  store.dispatch('captainWorkflows/get', {
    assistantId: assistantId.value,
  });
});
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.DOCUMENTS.HEADER')"
    :is-fetching="isFetching"
    :show-know-more="false"
    :show-pagination-footer="false"
  >
    <template #body>
      <SettingsHeader
        :heading="$t('CAPTAIN.ASSISTANTS.WORKFLOWS.TITLE')"
        :description="$t('CAPTAIN.ASSISTANTS.WORKFLOWS.DESCRIPTION')"
      />
      <div class="flex mt-7 flex-col gap-4">
        <div class="flex justify-between items-center">
          <Button
            :label="$t('CAPTAIN.ASSISTANTS.WORKFLOWS.ADD_BUTTON')"
            icon="i-lucide-plus"
            @click="createWorkflow"
          />
        </div>
        <div v-if="workflows.length === 0" class="mt-1 mb-2">
          <span class="text-n-slate-11 text-sm">
            {{ $t('CAPTAIN.ASSISTANTS.WORKFLOWS.EMPTY_MESSAGE') }}
          </span>
        </div>
        <div v-else class="flex flex-col gap-2">
          <div
            v-for="workflow in workflows"
            :key="workflow.id"
            class="flex items-center justify-between p-4 border border-n-weak rounded-lg bg-n-solid-2 hover:bg-n-solid-3 cursor-pointer"
            @click="editWorkflow(workflow.id)"
          >
            <div class="flex flex-col gap-1 min-w-0">
              <span class="text-sm font-medium text-n-slate-12 truncate">
                {{ workflow.name }}
              </span>
              <span
                v-if="workflow.description"
                class="text-xs text-n-slate-11 truncate"
              >
                {{ workflow.description }}
              </span>
              <span class="text-xs text-n-slate-10">
                {{ $t(TRIGGER_LABELS[workflow.trigger_event]) }}
              </span>
            </div>
            <div class="flex items-center gap-3 flex-shrink-0">
              <Switch
                :model-value="workflow.enabled"
                @click.stop
                @update:model-value="toggleWorkflow(workflow)"
              />
              <Button
                icon="i-lucide-trash-2"
                xs
                ghost
                slate
                @click.stop="deleteWorkflow(workflow.id)"
              />
            </div>
          </div>
        </div>
      </div>
    </template>
  </PageLayout>
</template>
