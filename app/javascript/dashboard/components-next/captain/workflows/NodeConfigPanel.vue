<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Textarea from 'dashboard/components-next/textarea/Textarea.vue';

const props = defineProps({
  node: { type: Object, required: true },
});

const emit = defineEmits(['update', 'delete', 'close']);
const { t } = useI18n();

const nodeData = ref({ ...props.node.data });

watch(
  () => props.node,
  val => {
    nodeData.value = { ...val.data };
  }
);

const FIELD_CONFIGS = {
  send_message: [
    {
      key: 'message',
      component: 'textarea',
      label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.MESSAGE',
    },
  ],
  add_label: [
    {
      key: 'label',
      component: 'input',
      label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.LABEL',
    },
  ],
  assign_agent: [
    {
      key: 'agent_id',
      component: 'input',
      label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.AGENT_ID',
    },
  ],
  assign_team: [
    {
      key: 'team_id',
      component: 'input',
      label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.TEAM_ID',
    },
  ],
  add_private_note: [
    {
      key: 'message',
      component: 'textarea',
      label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.MESSAGE',
    },
  ],
  update_priority: [
    {
      key: 'priority',
      component: 'input',
      label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.PRIORITY',
    },
  ],
  collect_input: [
    {
      key: 'input_key',
      component: 'input',
      label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.INPUT_KEY',
    },
    {
      key: 'prompt',
      component: 'textarea',
      label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.PROMPT',
    },
  ],
  condition: [
    {
      key: 'attribute',
      component: 'input',
      label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.ATTRIBUTE',
    },
    {
      key: 'operator',
      component: 'input',
      label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.OPERATOR',
    },
    {
      key: 'value',
      component: 'input',
      label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.VALUE',
    },
  ],
};

const fields = ref(FIELD_CONFIGS[props.node.type] || []);

watch(
  () => props.node.type,
  type => {
    fields.value = FIELD_CONFIGS[type] || [];
  }
);

const applyChanges = () => {
  emit('update', props.node.id, nodeData.value);
};

const deleteNode = () => {
  emit('delete', props.node.id);
};
</script>

<template>
  <div
    class="w-72 shrink-0 border-l border-n-weak bg-n-solid-2 overflow-y-auto flex flex-col"
  >
    <div
      class="flex justify-between items-center px-4 py-3 border-b border-n-weak"
    >
      <h3 class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.TITLE') }}
      </h3>
      <Button icon="i-lucide-x" xs ghost slate @click="emit('close')" />
    </div>

    <div class="flex flex-col gap-3 p-4">
      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.LABEL_FIELD') }}
        </label>
        <Input v-model="nodeData.label" @change="applyChanges" />
      </div>

      <div
        v-for="field in fields"
        :key="field.key"
        class="flex flex-col gap-1.5"
      >
        <label class="text-xs font-medium text-n-slate-11">
          {{ t(field.label) }}
        </label>
        <Textarea
          v-if="field.component === 'textarea'"
          v-model="nodeData[field.key]"
          rows="3"
          @change="applyChanges"
        />
        <Input v-else v-model="nodeData[field.key]" @change="applyChanges" />
      </div>
    </div>

    <div class="mt-auto flex items-center gap-2 p-4 border-t border-n-weak">
      <Button
        :label="t('CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.APPLY')"
        sm
        @click="applyChanges"
      />
      <Button
        :label="t('CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.DELETE')"
        icon="i-lucide-trash-2"
        sm
        ghost
        slate
        @click="deleteNode"
      />
    </div>
  </div>
</template>
