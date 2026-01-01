<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  assistant: {
    type: Object,
    required: true,
  },
  isSaving: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update', 'save']);

const { t } = useI18n();

const updateField = (field, value) => {
  emit('update', { [field]: value });
};

const toneOptions = computed(() => [
  { value: 'professional', label: t('ALOO.FORM.TONE.OPTIONS.PROFESSIONAL') },
  { value: 'friendly', label: t('ALOO.FORM.TONE.OPTIONS.FRIENDLY') },
  { value: 'casual', label: t('ALOO.FORM.TONE.OPTIONS.CASUAL') },
  { value: 'formal', label: t('ALOO.FORM.TONE.OPTIONS.FORMAL') },
]);

const formalityOptions = computed(() => [
  { value: 'high', label: t('ALOO.FORM.FORMALITY.OPTIONS.HIGH') },
  { value: 'medium', label: t('ALOO.FORM.FORMALITY.OPTIONS.MEDIUM') },
  { value: 'low', label: t('ALOO.FORM.FORMALITY.OPTIONS.LOW') },
]);

const empathyOptions = computed(() => [
  { value: 'high', label: t('ALOO.FORM.EMPATHY_LEVEL.OPTIONS.HIGH') },
  { value: 'medium', label: t('ALOO.FORM.EMPATHY_LEVEL.OPTIONS.MEDIUM') },
  { value: 'low', label: t('ALOO.FORM.EMPATHY_LEVEL.OPTIONS.LOW') },
]);

const verbosityOptions = computed(() => [
  { value: 'concise', label: t('ALOO.FORM.VERBOSITY.OPTIONS.CONCISE') },
  { value: 'balanced', label: t('ALOO.FORM.VERBOSITY.OPTIONS.BALANCED') },
  { value: 'detailed', label: t('ALOO.FORM.VERBOSITY.OPTIONS.DETAILED') },
]);

const emojiOptions = computed(() => [
  { value: 'none', label: t('ALOO.FORM.EMOJI_USAGE.OPTIONS.NONE') },
  { value: 'minimal', label: t('ALOO.FORM.EMOJI_USAGE.OPTIONS.MINIMAL') },
  { value: 'moderate', label: t('ALOO.FORM.EMOJI_USAGE.OPTIONS.MODERATE') },
]);

const languageOptions = computed(() => [
  { value: 'en', label: t('ALOO.FORM.LANGUAGE.OPTIONS.EN') },
  { value: 'ar', label: t('ALOO.FORM.LANGUAGE.OPTIONS.AR') },
  { value: 'fr', label: t('ALOO.FORM.LANGUAGE.OPTIONS.FR') },
  { value: 'es', label: t('ALOO.FORM.LANGUAGE.OPTIONS.ES') },
  { value: 'de', label: t('ALOO.FORM.LANGUAGE.OPTIONS.DE') },
  { value: 'pt', label: t('ALOO.FORM.LANGUAGE.OPTIONS.PT') },
  { value: 'it', label: t('ALOO.FORM.LANGUAGE.OPTIONS.IT') },
  { value: 'nl', label: t('ALOO.FORM.LANGUAGE.OPTIONS.NL') },
  { value: 'ru', label: t('ALOO.FORM.LANGUAGE.OPTIONS.RU') },
  { value: 'ja', label: t('ALOO.FORM.LANGUAGE.OPTIONS.JA') },
  { value: 'ko', label: t('ALOO.FORM.LANGUAGE.OPTIONS.KO') },
  { value: 'zh', label: t('ALOO.FORM.LANGUAGE.OPTIONS.ZH') },
]);

const dialectOptions = computed(() => [
  { value: 'EG', label: t('ALOO.FORM.DIALECT.OPTIONS.EG') },
  { value: 'SA', label: t('ALOO.FORM.DIALECT.OPTIONS.SA') },
  { value: 'AE', label: t('ALOO.FORM.DIALECT.OPTIONS.AE') },
  { value: 'KW', label: t('ALOO.FORM.DIALECT.OPTIONS.KW') },
  { value: 'QA', label: t('ALOO.FORM.DIALECT.OPTIONS.QA') },
  { value: 'BH', label: t('ALOO.FORM.DIALECT.OPTIONS.BH') },
  { value: 'OM', label: t('ALOO.FORM.DIALECT.OPTIONS.OM') },
  { value: 'JO', label: t('ALOO.FORM.DIALECT.OPTIONS.JO') },
  { value: 'LB', label: t('ALOO.FORM.DIALECT.OPTIONS.LB') },
  { value: 'SY', label: t('ALOO.FORM.DIALECT.OPTIONS.SY') },
  { value: 'IQ', label: t('ALOO.FORM.DIALECT.OPTIONS.IQ') },
  { value: 'MA', label: t('ALOO.FORM.DIALECT.OPTIONS.MA') },
  { value: 'TN', label: t('ALOO.FORM.DIALECT.OPTIONS.TN') },
  { value: 'DZ', label: t('ALOO.FORM.DIALECT.OPTIONS.DZ') },
  { value: 'LY', label: t('ALOO.FORM.DIALECT.OPTIONS.LY') },
  { value: 'SD', label: t('ALOO.FORM.DIALECT.OPTIONS.SD') },
  { value: 'PS', label: t('ALOO.FORM.DIALECT.OPTIONS.PS') },
  { value: 'MSA', label: t('ALOO.FORM.DIALECT.OPTIONS.MSA') },
]);

const showDialect = computed(() => props.assistant.language === 'ar');
</script>

<template>
  <div>
    <SettingsSection
      :title="$t('ALOO.SETTINGS.PERSONALITY.TITLE')"
      :sub-title="$t('ALOO.SETTINGS.PERSONALITY.DESCRIPTION')"
    >
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <label>
          {{ $t('ALOO.FORM.TONE.LABEL') }}
          <select
            :value="assistant.tone"
            @change="updateField('tone', $event.target.value)"
          >
            <option
              v-for="option in toneOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>
        <label>
          {{ $t('ALOO.FORM.FORMALITY.LABEL') }}
          <select
            :value="assistant.formality"
            @change="updateField('formality', $event.target.value)"
          >
            <option
              v-for="option in formalityOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>
        <label>
          {{ $t('ALOO.FORM.EMPATHY_LEVEL.LABEL') }}
          <select
            :value="assistant.empathy_level"
            @change="updateField('empathy_level', $event.target.value)"
          >
            <option
              v-for="option in empathyOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>
        <label>
          {{ $t('ALOO.FORM.VERBOSITY.LABEL') }}
          <select
            :value="assistant.verbosity"
            @change="updateField('verbosity', $event.target.value)"
          >
            <option
              v-for="option in verbosityOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>
        <label>
          {{ $t('ALOO.FORM.EMOJI_USAGE.LABEL') }}
          <select
            :value="assistant.emoji_usage"
            @change="updateField('emoji_usage', $event.target.value)"
          >
            <option
              v-for="option in emojiOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>
        <label>
          {{ $t('ALOO.FORM.LANGUAGE.LABEL') }}
          <select
            :value="assistant.language"
            @change="updateField('language', $event.target.value)"
          >
            <option
              v-for="option in languageOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>
        <label v-if="showDialect">
          {{ $t('ALOO.FORM.DIALECT.LABEL') }}
          <select
            :value="assistant.dialect"
            @change="updateField('dialect', $event.target.value)"
          >
            <option value="">{{ $t('ALOO.FORM.DIALECT.PLACEHOLDER') }}</option>
            <option
              v-for="option in dialectOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>
        <label class="md:col-span-2">
          {{ $t('ALOO.FORM.PERSONALITY_DESCRIPTION.LABEL') }}
          <textarea
            :value="assistant.personality_description"
            :placeholder="$t('ALOO.FORM.PERSONALITY_DESCRIPTION.PLACEHOLDER')"
            rows="4"
            @input="updateField('personality_description', $event.target.value)"
          />
        </label>
      </div>
      <div class="pt-4">
        <Button :is-loading="isSaving" @click="emit('save')">
          {{ $t('ALOO.ACTIONS.SAVE') }}
        </Button>
      </div>
    </SettingsSection>
  </div>
</template>
