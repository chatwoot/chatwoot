<script setup>
import { reactive, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

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
  provider: 'elevenlabs',
  voiceId: '',
  language: 'en',
  speed: 1.0,
  greeting: '',
  interruptionSensitivity: 'medium',
  realtimeModel: 'gpt-4o-realtime-preview',
});

const providerOptions = [
  { value: 'elevenlabs', label: 'ElevenLabs' },
  { value: 'openai', label: 'OpenAI Realtime' },
];

const sensitivityOptions = [
  { value: 'low', label: t('AI_AGENTS.VOICE.SENSITIVITY.LOW') },
  { value: 'medium', label: t('AI_AGENTS.VOICE.SENSITIVITY.MEDIUM') },
  { value: 'high', label: t('AI_AGENTS.VOICE.SENSITIVITY.HIGH') },
];

const isVoiceAgent = computed(
  () =>
    props.agent.agent_type === 'voice' || props.agent.agent_type === 'hybrid'
);

const syncFromAgent = agent => {
  if (!agent?.voice_config) return;
  const vc = agent.voice_config;
  state.provider = vc.provider || 'elevenlabs';
  state.voiceId = vc.voice_id || '';
  state.language = vc.language || 'en';
  state.speed = vc.speed ?? 1.0;
  state.greeting = vc.greeting || '';
  state.interruptionSensitivity = vc.interruption_sensitivity || 'medium';
  state.realtimeModel = vc.realtime_model || 'gpt-4o-realtime-preview';
};

watch(() => props.agent, syncFromAgent, { immediate: true });

const handleSubmit = async () => {
  try {
    await store.dispatch('aiAgents/update', {
      id: props.agent.id,
      voice_config: {
        provider: state.provider,
        voice_id: state.voiceId,
        language: state.language,
        speed: state.speed,
        greeting: state.greeting,
        interruption_sensitivity: state.interruptionSensitivity,
        realtime_model: state.realtimeModel,
      },
    });
    useAlert(t('AI_AGENTS.EDIT.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(error?.message || t('AI_AGENTS.EDIT.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <div class="flex flex-col gap-6 max-w-2xl">
    <div>
      <h2 class="text-base font-medium text-n-slate-12">
        {{ t('AI_AGENTS.TABS.VOICE') }}
      </h2>
      <p class="text-sm text-n-slate-11 mt-1">
        {{ t('AI_AGENTS.VOICE.DESCRIPTION') }}
      </p>
    </div>

    <div v-if="!isVoiceAgent" class="flex flex-col items-center py-12 gap-3">
      <div class="i-lucide-mic-off size-10 text-n-slate-8" />
      <p class="text-sm text-n-slate-11 text-center max-w-md">
        {{ t('AI_AGENTS.VOICE.NOT_VOICE_AGENT') }}
      </p>
    </div>

    <form v-else class="flex flex-col gap-5" @submit.prevent="handleSubmit">
      <fieldset class="flex flex-col gap-1.5">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('AI_AGENTS.VOICE.PROVIDER.LABEL') }}
        </label>
        <select
          v-model="state.provider"
          class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
        >
          <option
            v-for="opt in providerOptions"
            :key="opt.value"
            :value="opt.value"
          >
            {{ opt.label }}
          </option>
        </select>
      </fieldset>

      <Input
        v-model="state.voiceId"
        :label="t('AI_AGENTS.VOICE.VOICE_ID.LABEL')"
        :placeholder="t('AI_AGENTS.VOICE.VOICE_ID.PLACEHOLDER')"
      />

      <Input
        v-model="state.language"
        :label="t('AI_AGENTS.VOICE.LANGUAGE.LABEL')"
        :placeholder="t('AI_AGENTS.VOICE.LANGUAGE.PLACEHOLDER')"
      />

      <fieldset class="flex flex-col gap-1.5">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('AI_AGENTS.VOICE.SPEED.LABEL') }}
        </label>
        <div class="flex items-center gap-3">
          <input
            v-model.number="state.speed"
            type="range"
            min="0.5"
            max="2"
            step="0.1"
            class="flex-1"
          />
          <span class="text-sm font-mono text-n-slate-11 w-8 text-right">
            {{ state.speed }}
          </span>
        </div>
      </fieldset>

      <fieldset class="flex flex-col gap-1.5">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('AI_AGENTS.VOICE.GREETING.LABEL') }}
        </label>
        <textarea
          v-model="state.greeting"
          :placeholder="t('AI_AGENTS.VOICE.GREETING.PLACEHOLDER')"
          rows="3"
          class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7 resize-none"
        />
      </fieldset>

      <fieldset class="flex flex-col gap-1.5">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('AI_AGENTS.VOICE.SENSITIVITY.LABEL') }}
        </label>
        <select
          v-model="state.interruptionSensitivity"
          class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
        >
          <option
            v-for="opt in sensitivityOptions"
            :key="opt.value"
            :value="opt.value"
          >
            {{ opt.label }}
          </option>
        </select>
      </fieldset>

      <Input
        v-if="state.provider === 'openai'"
        v-model="state.realtimeModel"
        :label="t('AI_AGENTS.VOICE.REALTIME_MODEL.LABEL')"
        :placeholder="t('AI_AGENTS.VOICE.REALTIME_MODEL.PLACEHOLDER')"
      />

      <div class="flex justify-end pt-2">
        <Button
          type="submit"
          :label="t('AI_AGENTS.FORM.SAVE')"
          :is-loading="isUpdating"
          :disabled="isUpdating"
        />
      </div>
    </form>
  </div>
</template>
