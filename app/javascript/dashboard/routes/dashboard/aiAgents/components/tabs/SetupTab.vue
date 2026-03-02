<script setup>
import { reactive, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  agent: { type: Object, required: true },
});

const { t } = useI18n();
const store = useStore();
const uiFlags = useMapGetter('aiAgents/getUIFlags');
const isUpdating = computed(() => uiFlags.value.isUpdating);

const state = reactive({
  name: '',
  description: '',
  agentType: 'rag',
  model: '',
  systemPrompt: '',
  temperature: 0.7,
});

const rules = {
  name: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(rules, state);

const agentTypeOptions = [
  { value: 'rag', label: 'RAG (Knowledge Base)' },
  { value: 'tool_calling', label: 'Tool Calling' },
  { value: 'voice', label: 'Voice Agent' },
  { value: 'hybrid', label: 'Hybrid' },
];

const syncFromAgent = agent => {
  if (!agent) return;
  state.name = agent.name || '';
  state.description = agent.description || '';
  state.agentType = agent.agent_type || 'rag';
  state.model = agent.model || '';
  state.systemPrompt = agent.system_prompt || '';
  state.temperature = agent.llm_config?.temperature ?? 0.7;
};

watch(() => props.agent, syncFromAgent, { immediate: true });

const handleSubmit = async () => {
  const isValid = await v$.value.$validate();
  if (!isValid) return;

  try {
    await store.dispatch('aiAgents/update', {
      id: props.agent.id,
      name: state.name,
      description: state.description,
      agent_type: state.agentType,
      model: state.model,
      system_prompt: state.systemPrompt,
      llm_config: {
        ...props.agent.llm_config,
        temperature: state.temperature,
      },
    });
    useAlert(t('AI_AGENTS.EDIT.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(error?.message || t('AI_AGENTS.EDIT.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <form class="flex flex-col gap-6 max-w-2xl" @submit.prevent="handleSubmit">
    <div class="flex flex-col gap-1">
      <h2 class="text-base font-medium text-n-slate-12">
        {{ t('AI_AGENTS.TABS.SETUP') }}
      </h2>
      <p class="text-sm text-n-slate-11">
        {{ t('AI_AGENTS.FORM.SETUP_DESCRIPTION') }}
      </p>
    </div>

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
        rows="6"
        class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7 resize-none"
      />
    </fieldset>

    <fieldset class="flex flex-col gap-1.5">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('AI_AGENTS.FORM.TEMPERATURE.LABEL') }}
      </label>
      <div class="flex items-center gap-3">
        <input
          v-model.number="state.temperature"
          type="range"
          min="0"
          max="2"
          step="0.1"
          class="flex-1"
        />
        <span class="text-sm font-mono text-n-slate-11 w-8 text-right">
          {{ state.temperature }}
        </span>
      </div>
    </fieldset>

    <div class="flex justify-end pt-2">
      <Button
        type="submit"
        :label="t('AI_AGENTS.FORM.SAVE')"
        :is-loading="isUpdating"
        :disabled="isUpdating"
      />
    </div>
  </form>
</template>
