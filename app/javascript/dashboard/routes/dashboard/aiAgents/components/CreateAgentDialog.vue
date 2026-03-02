<script setup>
import { ref, computed, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  selectedAgent: {
    type: Object,
    default: () => ({}),
  },
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
});

const emit = defineEmits(['close', 'created']);

const { t } = useI18n();
const store = useStore();
const dialogRef = ref(null);

const uiFlags = useMapGetter('aiAgents/getUIFlags');
const isLoading = computed(
  () => uiFlags.value.isCreating || uiFlags.value.isUpdating
);

const state = reactive({
  name: '',
  description: '',
  agentType: 'rag',
  model: '',
  systemPrompt: '',
});

const rules = {
  name: { required, minLength: minLength(1) },
  description: {},
  agentType: { required },
};

const v$ = useVuelidate(rules, state);

const i18nKey = computed(() => `AI_AGENTS.${props.type.toUpperCase()}`);

const agentTypeOptions = [
  { value: 'rag', label: 'RAG (Knowledge Base)' },
  { value: 'tool_calling', label: 'Tool Calling' },
  { value: 'voice', label: 'Voice Agent' },
  { value: 'hybrid', label: 'Hybrid' },
];

const handleSubmit = async () => {
  const isValid = await v$.value.$validate();
  if (!isValid) return;

  const payload = {
    name: state.name,
    description: state.description,
    agent_type: state.agentType,
    model: state.model,
    system_prompt: state.systemPrompt,
  };

  try {
    if (props.type === 'edit') {
      await store.dispatch('aiAgents/update', {
        id: props.selectedAgent.id,
        ...payload,
      });
    } else {
      const newAgent = await store.dispatch('aiAgents/create', payload);
      emit('created', newAgent);
    }
    useAlert(t(`${i18nKey.value}.SUCCESS_MESSAGE`));
    dialogRef.value.close();
  } catch (error) {
    useAlert(error?.message || t(`${i18nKey.value}.ERROR_MESSAGE`));
  }
};

const handleClose = () => emit('close');

watch(
  () => props.selectedAgent,
  agent => {
    if (props.type === 'edit' && agent) {
      state.name = agent.name || '';
      state.description = agent.description || '';
      state.agentType = agent.agent_type || 'rag';
      state.model = agent.model || '';
      state.systemPrompt = agent.system_prompt || '';
    }
  },
  { immediate: true }
);

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="t(`${i18nKey}.TITLE`)"
    :show-cancel-button="false"
    :show-confirm-button="false"
    overflow-y-auto
    @close="handleClose"
  >
    <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
      <Input
        v-model="state.name"
        :label="t('AI_AGENTS.FORM.NAME.LABEL')"
        :placeholder="t('AI_AGENTS.FORM.NAME.PLACEHOLDER')"
        :message="v$.name.$error ? t('AI_AGENTS.FORM.NAME.ERROR') : ''"
        :message-type="v$.name.$error ? 'error' : 'info'"
      />

      <Input
        v-model="state.description"
        :label="t('AI_AGENTS.FORM.DESCRIPTION.LABEL')"
        :placeholder="t('AI_AGENTS.FORM.DESCRIPTION.PLACEHOLDER')"
      />

      <fieldset class="flex flex-col gap-1.5">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('AI_AGENTS.FORM.TYPE.LABEL') }}
        </label>
        <select
          v-model="state.agentType"
          class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
        >
          <option
            v-for="opt in agentTypeOptions"
            :key="opt.value"
            :value="opt.value"
          >
            {{ opt.label }}
          </option>
        </select>
      </fieldset>

      <Input
        v-model="state.model"
        :label="t('AI_AGENTS.FORM.MODEL.LABEL')"
        :placeholder="t('AI_AGENTS.FORM.MODEL.PLACEHOLDER')"
      />

      <fieldset class="flex flex-col gap-1.5">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('AI_AGENTS.FORM.SYSTEM_PROMPT.LABEL') }}
        </label>
        <textarea
          v-model="state.systemPrompt"
          :placeholder="t('AI_AGENTS.FORM.SYSTEM_PROMPT.PLACEHOLDER')"
          rows="4"
          class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7 resize-none"
        />
      </fieldset>

      <div class="flex items-center justify-between w-full gap-3 pt-2">
        <Button
          type="button"
          variant="faded"
          color="slate"
          :label="t('AI_AGENTS.FORM.CANCEL')"
          class="w-full bg-n-alpha-2 text-n-blue-11 hover:bg-n-alpha-3"
          @click="dialogRef.close()"
        />
        <Button
          type="submit"
          :label="t(`AI_AGENTS.FORM.${type.toUpperCase()}`)"
          class="w-full"
          :is-loading="isLoading"
          :disabled="isLoading"
        />
      </div>
    </form>

    <template #footer />
  </Dialog>
</template>
