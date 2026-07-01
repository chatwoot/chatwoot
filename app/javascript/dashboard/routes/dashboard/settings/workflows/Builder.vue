<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import { VueFlow, useVueFlow } from '@vue-flow/core';
import { Background } from '@vue-flow/background';
import { Controls } from '@vue-flow/controls';
import '@vue-flow/core/dist/style.css';
import '@vue-flow/core/dist/theme-default.css';
import '@vue-flow/controls/dist/style.css';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { onConnect, addEdges, addNodes, toObject } = useVueFlow();

const isEditing = ref(false);
const workflowName = ref('');
const triggerEvent = ref('message_created');

const nodes = ref([
  {
    id: '1',
    type: 'input',
    label: 'Trigger: Message Created',
    position: { x: 250, y: 5 },
    data: { type: 'trigger' },
  },
]);
const edges = ref([]);

onMounted(async () => {
  if (route.params.workflowId) {
    isEditing.value = true;
  }
});

onConnect(params => addEdges(params));

const saveWorkflow = async () => {
  const flowObject = toObject();
  const data = {
    name: workflowName.value,
    trigger_event: triggerEvent.value,
    nodes: flowObject.nodes,
    edges: flowObject.edges,
    active: true,
  };

  try {
    if (isEditing.value) {
      await store.dispatch('workflows/update', {
        id: route.params.workflowId,
        ...data,
      });
    } else {
      await store.dispatch('workflows/create', data);
    }
    useAlert(t('WORKFLOWS.SAVE.SUCCESS'));
    router.push({ name: 'workflows_list' });
  } catch (error) {
    useAlert(t('WORKFLOWS.SAVE.ERROR'));
  }
};

const addNode = type => {
  const labelMap = {
    condition: 'Condition',
    action: 'Send Message',
    ai_prompt: 'AI Prompt',
  };
  addNodes([
    {
      id: `node_${Date.now()}`,
      label: labelMap[type] || type,
      position: {
        x: Math.random() * 400,
        y: Math.random() * 400 + 100,
      },
      data: { type },
    },
  ]);
};
</script>

<template>
  <div class="flex flex-col h-full bg-slate-50 dark:bg-slate-900">
    <div
      class="flex items-center justify-between p-4 bg-white border-b shadow-sm dark:bg-slate-900 border-slate-200 dark:border-slate-800"
    >
      <div class="flex items-center gap-4">
        <Button
          variant="ghost"
          icon="arrow-left"
          @click="router.push({ name: 'workflows_list' })"
        />
        <div>
          <input
            v-model="workflowName"
            class="text-lg font-bold bg-transparent border-none outline-none dark:text-white"
            :placeholder="$t('WORKFLOWS.BUILDER.NAME_PLACEHOLDER')"
          />
        </div>
      </div>
      <div class="flex gap-2">
        <Button
          variant="outline"
          :label="$t('WORKFLOWS.BUILDER.ADD_CONDITION')"
          icon="split"
          @click="addNode('condition')"
        />
        <Button
          variant="outline"
          :label="$t('WORKFLOWS.BUILDER.ADD_ACTION')"
          icon="chat"
          @click="addNode('action')"
        />
        <Button
          variant="outline"
          :label="$t('WORKFLOWS.BUILDER.ADD_AI')"
          icon="sparkle"
          @click="addNode('ai_prompt')"
        />
        <Button
          :label="$t('WORKFLOWS.BUILDER.SAVE')"
          icon="save"
          @click="saveWorkflow"
        />
      </div>
    </div>

    <div class="relative flex-1 w-full h-full">
      <VueFlow
        :nodes="nodes"
        :edges="edges"
        :default-viewport="{ zoom: 1.5, x: 0, y: 0 }"
        :min-zoom="0.2"
        :max-zoom="4"
        fit-view-on-init
      >
        <Background pattern-color="#aaa" gap="16" />
        <Controls />
      </VueFlow>
    </div>
  </div>
</template>
