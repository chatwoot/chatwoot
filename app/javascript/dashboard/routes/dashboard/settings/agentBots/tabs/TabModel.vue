<script setup>
import { computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsSection from 'dashboard/components/SettingsSection.vue';

const props = defineProps({
  form: { type: Object, required: true },
});

const { t } = useI18n();

const OPENAI_MODELS = new Set(['gpt-4o-mini', 'gpt-5-nano', 'gpt-5-mini']);
const GOOGLE_MODELS = new Set(['gemini-2.5-flash']);
// Reasoning models don't expose temperature; passing a value != 1 raises 400
const NO_TEMPERATURE_MODELS = new Set(['gpt-5-nano', 'gpt-5-mini']);

const MODELS = [
  { id: 'gpt-4o-mini', key: 'gpt-4o-mini' },
  { id: 'gpt-5-nano', key: 'gpt-5-nano' },
  { id: 'gpt-5-mini', key: 'gpt-5-mini' },
  { id: 'gemini-2.5-flash', key: 'gemini-2_5-flash' },
];

const selectedModel = computed(
  () => props.form.agent_behavior_config.response.model_name
);
const showOpenAiKey = computed(() => OPENAI_MODELS.has(selectedModel.value));
const showGoogleKey = computed(() => GOOGLE_MODELS.has(selectedModel.value));
const showTemperature = computed(
  () => !NO_TEMPERATURE_MODELS.has(selectedModel.value)
);

watch(selectedModel, () => {
  if (!showOpenAiKey.value) props.form.openai_api_key = '';
  if (!showGoogleKey.value) props.form.google_api_key = '';
});

const WORD_LIMIT_OPTIONS = [
  { value: '20-40', key: 'short' },
  { value: '50-70', key: 'standard' },
  { value: '80-120', key: 'detailed' },
  { value: 'unlimited', key: 'unlimited' },
];
</script>

<template>
  <div>
    <SettingsSection
      :title="$t('AGENT_BOTS.CONFIG.MODEL.SECTION_MODEL')"
      :sub-title="$t('AGENT_BOTS.CONFIG.MODEL.SECTION_MODEL_DESC')"
    >
      <div class="flex flex-col gap-2">
        <label
          v-for="model in MODELS"
          :key="model.id"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg border cursor-pointer transition-colors"
          :class="
            form.agent_behavior_config.response.model_name === model.id
              ? 'border-n-brand bg-n-blue-1'
              : 'border-n-weak hover:bg-n-alpha-1'
          "
        >
          <input
            type="radio"
            :value="model.id"
            :checked="form.agent_behavior_config.response.model_name === model.id"
            class="accent-n-brand"
            @change="form.agent_behavior_config.response.model_name = model.id"
          />
          <span class="text-sm text-n-slate-12">
            {{ $t(`AGENT_BOTS.CONFIG.MODEL.MODELS.${model.key}`) }}
          </span>
        </label>
      </div>
    </SettingsSection>

    <SettingsSection
      v-if="showTemperature"
      :title="$t('AGENT_BOTS.CONFIG.MODEL.SECTION_TEMPERATURE')"
      :sub-title="$t('AGENT_BOTS.CONFIG.MODEL.SECTION_TEMPERATURE_DESC')"
    >
      <div class="flex flex-col gap-3">
        <div class="flex items-center justify-between">
          <label class="text-sm font-medium text-n-slate-12">
            {{ $t('AGENT_BOTS.CONFIG.MODEL.TEMPERATURE_LABEL') }}
          </label>
          <span class="text-sm font-semibold text-n-brand">
            {{ form.agent_behavior_config.response.temperature }}
          </span>
        </div>
        <input
          type="range"
          min="0"
          max="1"
          step="0.1"
          :value="form.agent_behavior_config.response.temperature"
          class="w-full accent-n-brand"
          @input="
            e =>
              (form.agent_behavior_config.response.temperature = parseFloat(
                e.target.value
              ))
          "
        />
        <div class="flex justify-between text-xs text-n-slate-10">
          <span>0.0 — {{ $t('AGENT_BOTS.CONFIG.MODEL.TEMPERATURE_HINT_LOW') }}</span>
          <span>1.0 — {{ $t('AGENT_BOTS.CONFIG.MODEL.TEMPERATURE_HINT_HIGH') }}</span>
        </div>
        <p class="text-xs text-n-slate-11">
          {{ $t('AGENT_BOTS.CONFIG.MODEL.TEMPERATURE_DESC') }}
        </p>
      </div>
    </SettingsSection>

    <SettingsSection
      :title="$t('AGENT_BOTS.CONFIG.MODEL.SECTION_WORD_LIMIT')"
      :sub-title="$t('AGENT_BOTS.CONFIG.MODEL.SECTION_WORD_LIMIT_DESC')"
    >
      <div class="flex flex-col gap-2">
        <label
          v-for="opt in WORD_LIMIT_OPTIONS"
          :key="opt.value"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg border cursor-pointer transition-colors"
          :class="
            form.agent_behavior_config.response.response_word_limit === opt.value
              ? 'border-n-brand bg-n-blue-1'
              : 'border-n-weak hover:bg-n-alpha-1'
          "
        >
          <input
            type="radio"
            :value="opt.value"
            :checked="
              form.agent_behavior_config.response.response_word_limit ===
              opt.value
            "
            class="accent-n-brand"
            @change="
              form.agent_behavior_config.response.response_word_limit = opt.value
            "
          />
          <span class="text-sm text-n-slate-12">
            {{ $t(`AGENT_BOTS.CONFIG.MODEL.WORD_LIMIT_OPTIONS.${opt.key}`) }}
          </span>
        </label>
        <p class="text-xs text-n-slate-11 mt-1">
          {{ $t('AGENT_BOTS.CONFIG.MODEL.WORD_LIMIT_HINT') }}
        </p>
      </div>
    </SettingsSection>

    <SettingsSection
      :title="$t('AGENT_BOTS.CONFIG.MODEL.SECTION_CONTEXT')"
      :sub-title="$t('AGENT_BOTS.CONFIG.MODEL.SECTION_CONTEXT_DESC')"
    >
      <div class="flex flex-col gap-2">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('AGENT_BOTS.CONFIG.MODEL.MAX_TOKENS_LABEL') }}
        </label>
        <input
          type="number"
          :value="form.agent_behavior_config.response.max_context_tokens"
          min="100"
          max="8000"
          step="100"
          class="w-32 px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
          @input="
            e =>
              (form.agent_behavior_config.response.max_context_tokens = parseInt(
                e.target.value
              ))
          "
        />
        <p class="text-xs text-n-slate-11">
          {{ $t('AGENT_BOTS.CONFIG.MODEL.MAX_TOKENS_HINT') }}
        </p>
      </div>
    </SettingsSection>

    <SettingsSection
      v-if="showOpenAiKey || showGoogleKey"
      :title="$t('AGENT_BOTS.CONFIG.MODEL.SECTION_API_KEYS')"
      :sub-title="$t('AGENT_BOTS.CONFIG.MODEL.SECTION_API_KEYS_DESC')"
      :show-border="false"
    >
      <div class="flex flex-col gap-4">
        <div v-if="showOpenAiKey" class="flex flex-col gap-1">
          <label class="text-sm font-medium text-n-slate-12">
            {{ $t('AGENT_BOTS.CONFIG.MODEL.OPENAI_API_KEY_LABEL') }}
          </label>
          <input
            type="password"
            :value="form.openai_api_key"
            :placeholder="$t('AGENT_BOTS.CONFIG.MODEL.OPENAI_API_KEY_PLACEHOLDER')"
            class="px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
            @input="e => (form.openai_api_key = e.target.value)"
          />
          <p class="text-xs text-n-slate-11">
            {{
              form.has_openai_api_key
                ? $t('AGENT_BOTS.CONFIG.MODEL.OPENAI_API_KEY_SET_HINT')
                : $t('AGENT_BOTS.CONFIG.MODEL.OPENAI_API_KEY_HINT')
            }}
          </p>
        </div>
        <div v-if="showGoogleKey" class="flex flex-col gap-1">
          <label class="text-sm font-medium text-n-slate-12">
            {{ $t('AGENT_BOTS.CONFIG.MODEL.GOOGLE_API_KEY_LABEL') }}
          </label>
          <input
            type="password"
            :value="form.google_api_key"
            :placeholder="$t('AGENT_BOTS.CONFIG.MODEL.GOOGLE_API_KEY_PLACEHOLDER')"
            class="px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
            @input="e => (form.google_api_key = e.target.value)"
          />
          <p class="text-xs text-n-slate-11">
            {{
              form.has_google_api_key
                ? $t('AGENT_BOTS.CONFIG.MODEL.GOOGLE_API_KEY_SET_HINT')
                : $t('AGENT_BOTS.CONFIG.MODEL.GOOGLE_API_KEY_HINT')
            }}
          </p>
        </div>
      </div>
    </SettingsSection>
  </div>
</template>
