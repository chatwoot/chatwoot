<script setup>
import {
  reactive,
  ref,
  watch,
  computed,
  onMounted,
  onBeforeUnmount,
} from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Button from 'dashboard/components-next/button/Button.vue';
import VoiceSelector from '../voice/VoiceSelector.vue';
import AiAgentsAPI from 'dashboard/api/saas/aiAgents';

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
  modelId: '',
});

// Provider labels — no vendor names exposed
const providerOptions = [
  { value: 'elevenlabs', label: t('AI_AGENTS.VOICE.PROVIDER.STANDARD') },
  { value: 'openai', label: t('AI_AGENTS.VOICE.PROVIDER.REALTIME') },
];

const sensitivityOptions = [
  { value: 'low', label: t('AI_AGENTS.VOICE.SENSITIVITY.LOW') },
  { value: 'medium', label: t('AI_AGENTS.VOICE.SENSITIVITY.MEDIUM') },
  { value: 'high', label: t('AI_AGENTS.VOICE.SENSITIVITY.HIGH') },
];

const LANGUAGE_OPTIONS = [
  { value: 'en', label: 'English' },
  { value: 'es', label: 'Spanish' },
  { value: 'pt', label: 'Portuguese' },
  { value: 'fr', label: 'French' },
  { value: 'de', label: 'German' },
  { value: 'it', label: 'Italian' },
  { value: 'ja', label: 'Japanese' },
  { value: 'ko', label: 'Korean' },
  { value: 'zh', label: 'Chinese' },
  { value: 'ar', label: 'Arabic' },
  { value: 'hi', label: 'Hindi' },
  { value: 'pl', label: 'Polish' },
  { value: 'nl', label: 'Dutch' },
  { value: 'ru', label: 'Russian' },
  { value: 'tr', label: 'Turkish' },
  { value: 'sv', label: 'Swedish' },
  { value: 'id', label: 'Indonesian' },
  { value: 'fil', label: 'Filipino' },
  { value: 'uk', label: 'Ukrainian' },
  { value: 'el', label: 'Greek' },
  { value: 'cs', label: 'Czech' },
  { value: 'ro', label: 'Romanian' },
  { value: 'da', label: 'Danish' },
  { value: 'hu', label: 'Hungarian' },
  { value: 'no', label: 'Norwegian' },
  { value: 'fi', label: 'Finnish' },
  { value: 'bg', label: 'Bulgarian' },
  { value: 'hr', label: 'Croatian' },
  { value: 'sk', label: 'Slovak' },
  { value: 'ms', label: 'Malay' },
  { value: 'ta', label: 'Tamil' },
];

// Language-specific default test phrases
const DEFAULT_TEST_PHRASES = {
  en: 'Hello! How can I help you today?',
  es: '¡Hola! ¿En qué puedo ayudarte hoy?',
  pt: 'Olá! Como posso te ajudar hoje?',
  fr: "Bonjour ! Comment puis-je vous aider aujourd'hui ?",
  de: 'Hallo! Wie kann ich Ihnen heute helfen?',
  it: 'Ciao! Come posso aiutarti oggi?',
  ja: 'こんにちは！今日はどのようにお手伝いできますか？',
  ko: '안녕하세요! 오늘 어떻게 도와드릴까요?',
  zh: '你好！今天我能帮你什么？',
  ar: 'مرحبًا! كيف يمكنني مساعدتك اليوم؟',
  hi: 'नमस्ते! आज मैं आपकी कैसे मदद कर सकता हूँ?',
  pl: 'Cześć! Jak mogę ci dziś pomóc?',
  nl: 'Hallo! Hoe kan ik je vandaag helpen?',
  ru: 'Здравствуйте! Чем я могу вам помочь сегодня?',
  tr: 'Merhaba! Bugün size nasıl yardımcı olabilirim?',
  sv: 'Hej! Hur kan jag hjälpa dig idag?',
  id: 'Halo! Bagaimana saya bisa membantu Anda hari ini?',
  fil: 'Kumusta! Paano kita matutulungan ngayon?',
  uk: 'Привіт! Як я можу допомогти вам сьогодні?',
  el: 'Γεια σας! Πώς μπορώ να σας βοηθήσω σήμερα;',
  cs: 'Ahoj! Jak vám dnes mohu pomoci?',
  ro: 'Bună! Cum vă pot ajuta astăzi?',
  da: 'Hej! Hvordan kan jeg hjælpe dig i dag?',
  hu: 'Helló! Miben segíthetek ma?',
  no: 'Hei! Hvordan kan jeg hjelpe deg i dag?',
  fi: 'Hei! Kuinka voin auttaa sinua tänään?',
  bg: 'Здравейте! Как мога да ви помогна днес?',
  hr: 'Bok! Kako vam mogu pomoći danas?',
  sk: 'Ahoj! Ako vám dnes môžem pomôcť?',
  ms: 'Hai! Bagaimana saya boleh membantu anda hari ini?',
  ta: 'வணக்கம்! இன்று நான் உங்களுக்கு எப்படி உதவ முடியும்?',
};

const isVoiceAgent = computed(
  () =>
    props.agent.agent_type === 'voice' || props.agent.agent_type === 'hybrid'
);

// Catalog data
const voices = ref([]);
const models = ref([]);
const isCatalogLoading = ref(false);

// Test voice
const isTestingVoice = ref(false);
const testAudio = ref(null);

const syncFromAgent = agent => {
  if (!agent?.voice_config) return;
  const vc = agent.voice_config;
  state.provider = vc.provider || 'elevenlabs';
  state.voiceId = vc.elevenlabs_voice_id || vc.voice_id || vc.voice || '';
  state.language = vc.language || 'en';
  state.speed = vc.speed ?? 1.0;
  state.greeting = vc.greeting || '';
  state.interruptionSensitivity = vc.interruption_sensitivity || 'medium';
  state.modelId = vc.elevenlabs_model_id || vc.realtime_model || '';
};

watch(() => props.agent, syncFromAgent, { immediate: true });

const fetchCatalog = async () => {
  if (!props.agent?.id) return;
  isCatalogLoading.value = true;
  try {
    const { data } = await AiAgentsAPI.getVoiceCatalog(
      props.agent.id,
      state.provider
    );
    voices.value = data.voices || [];
    models.value = data.models || [];
  } catch {
    voices.value = [];
    models.value = [];
  } finally {
    isCatalogLoading.value = false;
  }
};

watch(() => state.provider, fetchCatalog);
onMounted(fetchCatalog);

const buildVoiceConfig = () => {
  const base = {
    provider: state.provider,
    language: state.language,
    speed: state.speed,
    greeting: state.greeting,
    interruption_sensitivity: state.interruptionSensitivity,
  };

  if (state.provider === 'elevenlabs') {
    base.elevenlabs_voice_id = state.voiceId;
    base.elevenlabs_model_id = state.modelId;
  } else {
    base.voice = state.voiceId;
    base.realtime_model = state.modelId;
  }

  // Preserve existing keys not managed by this form
  const existing = props.agent.voice_config || {};
  const preserveKeys = [
    'elevenlabs_agent_id',
    'realtime_enabled',
    'stability',
    'similarity_boost',
    'style',
    'use_speaker_boost',
    'output_format',
    'vad_type',
    'vad_threshold',
    'silence_duration_ms',
    'noise_reduction',
    'twilio_voice',
  ];
  preserveKeys.forEach(k => {
    if (existing[k] !== undefined) base[k] = existing[k];
  });

  return base;
};

const handleSubmit = async () => {
  try {
    await store.dispatch('aiAgents/update', {
      id: props.agent.id,
      voice_config: buildVoiceConfig(),
    });
    useAlert(t('AI_AGENTS.EDIT.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(error?.message || t('AI_AGENTS.EDIT.ERROR_MESSAGE'));
  }
};

const testVoice = async () => {
  if (!state.voiceId) return;
  isTestingVoice.value = true;

  try {
    const defaultText =
      DEFAULT_TEST_PHRASES[state.language] || DEFAULT_TEST_PHRASES.en;
    const { data } = await AiAgentsAPI.previewVoice(props.agent.id, {
      voiceId: state.voiceId,
      text: state.greeting || defaultText,
      modelId: state.modelId,
      provider: state.provider,
      language: state.language,
    });

    if (data.audio) {
      if (testAudio.value) testAudio.value.pause();
      const audio = new Audio(`data:audio/mpeg;base64,${data.audio}`);
      testAudio.value = audio;
      audio.addEventListener('ended', () => {
        isTestingVoice.value = false;
      });
      audio.play();
    } else {
      isTestingVoice.value = false;
    }
  } catch {
    useAlert(t('AI_AGENTS.VOICE.TEST.ERROR'));
    isTestingVoice.value = false;
  }
};

onBeforeUnmount(() => {
  if (testAudio.value) {
    testAudio.value.pause();
    testAudio.value = null;
  }
});

const speedLabel = computed(() => {
  if (state.speed <= 0.6) return t('AI_AGENTS.VOICE.SPEED.SLOW');
  if (state.speed >= 1.8) return t('AI_AGENTS.VOICE.SPEED.FAST');
  return t('AI_AGENTS.VOICE.SPEED.NORMAL');
});
</script>

<template>
  <div class="flex flex-col gap-6 max-w-2xl">
    <div>
      <h2 class="text-base font-medium text-n-slate-12">
        {{ t('AI_AGENTS.VOICE.TITLE') }}
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
      <!-- Voice Engine -->
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

      <!-- Voice Selection -->
      <fieldset class="flex flex-col gap-1.5">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('AI_AGENTS.VOICE.VOICE_ID.LABEL') }}
        </label>
        <VoiceSelector
          v-model="state.voiceId"
          :voices="voices"
          :is-loading="isCatalogLoading"
        />
      </fieldset>

      <!-- Language -->
      <fieldset class="flex flex-col gap-1.5">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('AI_AGENTS.VOICE.LANGUAGE.LABEL') }}
        </label>
        <select
          v-model="state.language"
          class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
        >
          <option
            v-for="lang in LANGUAGE_OPTIONS"
            :key="lang.value"
            :value="lang.value"
          >
            {{ lang.label }}
          </option>
        </select>
      </fieldset>

      <!-- Voice Model -->
      <fieldset v-if="models.length > 0" class="flex flex-col gap-1.5">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('AI_AGENTS.VOICE.MODEL.LABEL') }}
        </label>
        <select
          v-model="state.modelId"
          class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
        >
          <option value="" disabled>
            {{ t('AI_AGENTS.VOICE.MODEL.PLACEHOLDER') }}
          </option>
          <option v-for="m in models" :key="m.id" :value="m.id">
            {{ m.name }}
          </option>
        </select>
      </fieldset>

      <!-- Speed -->
      <fieldset class="flex flex-col gap-1.5">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('AI_AGENTS.VOICE.SPEED.LABEL') }}
        </label>
        <div class="flex items-center gap-3">
          <span class="text-xs text-n-slate-10 w-8">
            {{ t('AI_AGENTS.VOICE.SPEED.SLOW') }}
          </span>
          <input
            v-model.number="state.speed"
            type="range"
            min="0.5"
            max="2"
            step="0.1"
            class="flex-1"
          />
          <span class="text-xs text-n-slate-10 w-8 text-right">
            {{ t('AI_AGENTS.VOICE.SPEED.FAST') }}
          </span>
        </div>
        <div class="flex justify-center">
          <span class="text-xs text-n-slate-11 font-mono">
            <!-- eslint-disable-next-line vue/no-bare-strings-in-template -->
            {{ state.speed.toFixed(1) }}x · {{ speedLabel }}
          </span>
        </div>
      </fieldset>

      <!-- Greeting -->
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

      <!-- Interruption Sensitivity -->
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

      <!-- Actions -->
      <div class="flex items-center justify-between pt-2">
        <Button
          v-if="state.voiceId && state.provider === 'elevenlabs'"
          type="button"
          variant="smooth"
          color-scheme="secondary"
          :label="
            isTestingVoice
              ? t('AI_AGENTS.VOICE.TEST.TESTING')
              : t('AI_AGENTS.VOICE.TEST.LABEL')
          "
          icon="i-lucide-volume-2"
          :is-loading="isTestingVoice"
          :disabled="isTestingVoice"
          @click="testVoice"
        />
        <span v-else />
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
