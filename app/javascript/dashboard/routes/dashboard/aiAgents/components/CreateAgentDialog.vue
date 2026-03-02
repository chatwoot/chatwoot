<script setup>
import { ref, computed, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAvailableModels } from 'dashboard/composables/useAvailableModels';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import SetupWizardChat from './wizard/SetupWizardChat.vue';

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

// 'choose' | 'wizard' | 'quick'
const creationMode = ref(props.type === 'edit' ? 'quick' : 'choose');

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

const { modelGroupOptions, isLoadingModels } = useAvailableModels();

const i18nKey = computed(() => `AI_AGENTS.${props.type.toUpperCase()}`);

const dialogTitle = computed(() => {
  if (props.type === 'edit') return t(`${i18nKey.value}.TITLE`);
  if (creationMode.value === 'wizard') return t('AI_AGENTS.WIZARD.TITLE');
  return t(`${i18nKey.value}.TITLE`);
});

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

const handleWizardCreated = agent => {
  emit('created', agent);
  dialogRef.value.close();
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
    :title="dialogTitle"
    :show-cancel-button="false"
    :show-confirm-button="false"
    overflow-y-auto
    @close="handleClose"
  >
    <!-- Creation Mode Chooser -->
    <div
      v-if="type === 'create' && creationMode === 'choose'"
      class="flex flex-col gap-4"
    >
      <p class="text-sm text-n-slate-11">
        {{ t('AI_AGENTS.FORM.SETUP_DESCRIPTION') }}
      </p>
      <div class="grid grid-cols-2 gap-3">
        <!-- Guided Wizard -->
        <button
          type="button"
          class="flex flex-col items-center gap-3 p-5 rounded-xl border-2 border-n-weak hover:border-n-blue-7 bg-n-solid-2 hover:bg-n-alpha-2 transition-all group text-center"
          @click="creationMode = 'wizard'"
        >
          <span
            class="i-lucide-sparkles size-8 text-n-blue-9 group-hover:text-n-blue-11 transition-colors"
          />
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('AI_AGENTS.FORM.GUIDED_SETUP') }}
          </span>
          <span class="text-xs text-n-slate-10">
            {{ t('AI_AGENTS.WIZARD.GUIDED_DESCRIPTION') }}
          </span>
        </button>
        <!-- Quick Create -->
        <button
          type="button"
          class="flex flex-col items-center gap-3 p-5 rounded-xl border-2 border-n-weak hover:border-n-blue-7 bg-n-solid-2 hover:bg-n-alpha-2 transition-all group text-center"
          @click="creationMode = 'quick'"
        >
          <span
            class="i-lucide-zap size-8 text-n-slate-10 group-hover:text-n-blue-11 transition-colors"
          />
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('AI_AGENTS.FORM.QUICK_CREATE') }}
          </span>
          <span class="text-xs text-n-slate-10">
            {{ t('AI_AGENTS.FORM.SETUP_DESCRIPTION') }}
          </span>
        </button>
      </div>
    </div>

    <!-- Wizard Mode -->
    <SetupWizardChat
      v-else-if="type === 'create' && creationMode === 'wizard'"
      @created="handleWizardCreated"
      @skip="creationMode = 'quick'"
    />

    <!-- Quick Create / Edit Form -->
    <form v-else class="flex flex-col gap-4" @submit.prevent="handleSubmit">
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

      <fieldset class="flex flex-col gap-1.5">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('AI_AGENTS.FORM.MODEL.LABEL') }}
        </label>
        <select
          v-model="state.model"
          :disabled="isLoadingModels"
          class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
        >
          <option value="" disabled>
            {{
              isLoadingModels
                ? t('AI_AGENTS.FORM.MODEL.LOADING')
                : t('AI_AGENTS.FORM.MODEL.PLACEHOLDER')
            }}
          </option>
          <optgroup
            v-for="group in modelGroupOptions"
            :key="group.label"
            :label="group.label"
          >
            <option
              v-for="opt in group.options"
              :key="opt.value"
              :value="opt.value"
              :disabled="opt.disabled"
            >
              {{ opt.label }}
            </option>
          </optgroup>
        </select>
      </fieldset>

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
