<script setup>
import { reactive, ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAvailableModels } from 'dashboard/composables/useAvailableModels';
import { useGenerateSection } from '../../composables/useGenerateSection';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  agent: { type: Object, required: true },
});

const { t } = useI18n();
const store = useStore();
const uiFlags = useMapGetter('aiAgents/getUIFlags');
const isUpdating = computed(() => uiFlags.value.isUpdating);
const showAdvanced = ref(false);

const SECTION_KEYS = [
  'initial_message',
  'instructions',
  'general_context',
  'success_criteria',
  'interruption_rules',
  'inactivity',
  'error_message',
];

const SECTION_I18N_MAP = {
  initial_message: 'INITIAL_MESSAGE',
  instructions: 'INSTRUCTIONS',
  general_context: 'GENERAL_CONTEXT',
  success_criteria: 'SUCCESS_CRITERIA',
  interruption_rules: 'INTERRUPTION_RULES',
  inactivity: 'INACTIVITY',
  error_message: 'ERROR_MESSAGE',
};

const SECTION_ICONS = {
  initial_message: 'i-lucide-message-circle',
  instructions: 'i-lucide-scroll-text',
  general_context: 'i-lucide-building-2',
  success_criteria: 'i-lucide-check-circle',
  interruption_rules: 'i-lucide-hand',
  inactivity: 'i-lucide-clock',
  error_message: 'i-lucide-alert-triangle',
};

const state = reactive({
  name: '',
  description: '',
  agentType: 'rag',
  model: '',
  systemPrompt: '',
  temperature: 0.7,
  promptSections: {
    initial_message: '',
    instructions: '',
    general_context: '',
    success_criteria: '',
    interruption_rules: '',
    inactivity_message: '',
    inactivity_timeout_minutes: 5,
    error_message: '',
  },
});

const expandedSections = reactive(
  Object.fromEntries(SECTION_KEYS.map(k => [k, false]))
);

const rules = {
  name: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(rules, state);

const { modelGroupOptions, isLoadingModels } = useAvailableModels();
const { isGenerating, generatingSection, generateSection } =
  useGenerateSection();

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

  const sections = agent.config?.prompt_sections || {};
  state.promptSections.initial_message = sections.initial_message || '';
  state.promptSections.instructions = sections.instructions || '';
  state.promptSections.general_context = sections.general_context || '';
  state.promptSections.success_criteria = sections.success_criteria || '';
  state.promptSections.interruption_rules = sections.interruption_rules || '';
  state.promptSections.inactivity_message = sections.inactivity_message || '';
  state.promptSections.inactivity_timeout_minutes =
    sections.inactivity_timeout_minutes ?? 5;
  state.promptSections.error_message = sections.error_message || '';
};

watch(() => props.agent, syncFromAgent, { immediate: true });

const toggleSection = key => {
  expandedSections[key] = !expandedSections[key];
};

const sectionLabel = key =>
  t(`AI_AGENTS.FORM.SECTIONS.${SECTION_I18N_MAP[key]}.LABEL`);
const sectionDesc = key =>
  t(`AI_AGENTS.FORM.SECTIONS.${SECTION_I18N_MAP[key]}.DESCRIPTION`);
const sectionPlaceholder = key =>
  t(`AI_AGENTS.FORM.SECTIONS.${SECTION_I18N_MAP[key]}.PLACEHOLDER`);

const sectionHasContent = key => {
  if (key === 'inactivity') {
    return !!state.promptSections.inactivity_message;
  }
  return !!state.promptSections[key];
};

const handleGenerateSection = async (key, event) => {
  event.stopPropagation();
  const sectionKey = key === 'inactivity' ? 'inactivity_message' : key;
  const result = await generateSection(sectionKey, {
    name: state.name,
    description: state.description,
  });
  if (result) {
    if (key === 'inactivity') {
      state.promptSections.inactivity_message = result;
    } else {
      state.promptSections[key] = result;
    }
    // Auto-expand the section
    expandedSections[key] = true;
  }
};

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
      config: {
        ...props.agent.config,
        prompt_sections: { ...state.promptSections },
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
    <!-- Header -->
    <div class="flex flex-col gap-1">
      <h2 class="text-base font-medium text-n-slate-12">
        {{ t('AI_AGENTS.TABS.SETUP') }}
      </h2>
      <p class="text-sm text-n-slate-11">
        {{ t('AI_AGENTS.FORM.SETUP_DESCRIPTION') }}
      </p>
    </div>

    <!-- Basic Info -->
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

    <!-- Divider -->
    <hr class="border-n-weak" />

    <!-- 7-Part Structured Config Sections -->
    <div class="flex flex-col gap-3">
      <h3 class="text-sm font-medium text-n-slate-12">
        {{ t('AI_AGENTS.FORM.SETUP_DESCRIPTION') }}
      </h3>

      <div
        v-for="key in SECTION_KEYS"
        :key="key"
        class="rounded-lg border border-n-weak overflow-hidden"
      >
        <!-- Section Header (Collapsible Toggle) -->
        <div
          class="flex items-center justify-between w-full px-4 py-3 hover:bg-n-solid-3 transition-colors"
        >
          <button
            type="button"
            class="flex items-center gap-2.5 flex-1 text-left"
            @click="toggleSection(key)"
          >
            <span
              :class="SECTION_ICONS[key]"
              class="size-4 text-n-slate-10 shrink-0"
            />
            <span class="text-sm font-medium text-n-slate-12">
              {{ sectionLabel(key) }}
            </span>
            <span
              v-if="sectionHasContent(key)"
              class="size-1.5 rounded-full bg-n-blue-9"
            />
          </button>
          <div class="flex items-center gap-1.5">
            <!-- Generate with AI button -->
            <button
              type="button"
              class="flex items-center gap-1 px-2 py-1 rounded-md text-xs text-n-slate-10 hover:text-n-blue-11 hover:bg-n-alpha-2 transition-colors"
              :disabled="isGenerating"
              @click="handleGenerateSection(key, $event)"
            >
              <span
                class="size-3.5"
                :class="
                  isGenerating &&
                  generatingSection ===
                    (key === 'inactivity' ? 'inactivity_message' : key)
                    ? 'i-lucide-loader-2 animate-spin'
                    : 'i-lucide-sparkles'
                "
              />
              <span class="hidden sm:inline">
                {{ t('AI_AGENTS.FORM.GENERATE_WITH_AI') }}
              </span>
            </button>
            <button type="button" @click="toggleSection(key)">
              <span
                class="i-lucide-chevron-down size-4 text-n-slate-10 transition-transform duration-200"
                :class="{ 'rotate-180': expandedSections[key] }"
              />
            </button>
          </div>
        </div>

        <!-- Section Body -->
        <div v-if="expandedSections[key]" class="px-4 pb-4 pt-1">
          <p class="text-xs text-n-slate-10 mb-3">
            {{ sectionDesc(key) }}
          </p>

          <!-- Inactivity section has both timeout and message -->
          <template v-if="key === 'inactivity'">
            <div class="flex flex-col gap-3">
              <fieldset class="flex flex-col gap-1.5">
                <label class="text-xs font-medium text-n-slate-11">
                  {{ t('AI_AGENTS.FORM.SECTIONS.INACTIVITY.TIMEOUT_LABEL') }}
                </label>
                <input
                  v-model.number="
                    state.promptSections.inactivity_timeout_minutes
                  "
                  type="number"
                  min="1"
                  max="60"
                  :placeholder="
                    t('AI_AGENTS.FORM.SECTIONS.INACTIVITY.TIMEOUT_PLACEHOLDER')
                  "
                  class="w-32 px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
                />
              </fieldset>
              <fieldset class="flex flex-col gap-1.5">
                <label class="text-xs font-medium text-n-slate-11">
                  {{ t('AI_AGENTS.FORM.SECTIONS.INACTIVITY.MESSAGE_LABEL') }}
                </label>
                <textarea
                  v-model="state.promptSections.inactivity_message"
                  :placeholder="
                    t('AI_AGENTS.FORM.SECTIONS.INACTIVITY.MESSAGE_PLACEHOLDER')
                  "
                  rows="3"
                  class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7 resize-none"
                />
              </fieldset>
            </div>
          </template>

          <!-- All other sections have a single textarea -->
          <template v-else>
            <textarea
              v-model="state.promptSections[key]"
              :placeholder="sectionPlaceholder(key)"
              rows="4"
              class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7 resize-none"
            />
          </template>
        </div>
      </div>
    </div>

    <!-- Temperature -->
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

    <!-- Advanced Mode Toggle -->
    <div class="flex flex-col gap-3">
      <button
        type="button"
        class="flex items-center gap-2 text-sm text-n-slate-10 hover:text-n-slate-12 transition-colors"
        @click="showAdvanced = !showAdvanced"
      >
        <span class="i-lucide-code-2 size-4" />
        {{ t('AI_AGENTS.FORM.ADVANCED_MODE') }}
        <span
          class="i-lucide-chevron-down size-3.5 transition-transform duration-200"
          :class="{ 'rotate-180': showAdvanced }"
        />
      </button>
      <div v-if="showAdvanced" class="flex flex-col gap-1.5">
        <p class="text-xs text-n-slate-10">
          {{ t('AI_AGENTS.FORM.ADVANCED_DESCRIPTION') }}
        </p>
        <fieldset class="flex flex-col gap-1.5">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('AI_AGENTS.FORM.SYSTEM_PROMPT.LABEL') }}
          </label>
          <textarea
            v-model="state.systemPrompt"
            :placeholder="t('AI_AGENTS.FORM.SYSTEM_PROMPT.PLACEHOLDER')"
            rows="8"
            class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7 resize-y font-mono"
          />
        </fieldset>
      </div>
    </div>

    <!-- Save -->
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
