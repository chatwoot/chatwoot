<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
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
]);

const selectClasses =
  'w-full px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7';
</script>

<template>
  <div>
    <SettingsSection
      :title="$t('ALOO.SETTINGS.PERSONALITY.TITLE')"
      :sub-title="$t('ALOO.SETTINGS.PERSONALITY.DESCRIPTION')"
    >
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.TONE.LABEL') }}
          </label>
          <select
            :value="assistant.tone"
            :class="selectClasses"
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
        </div>
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.FORMALITY.LABEL') }}
          </label>
          <select
            :value="assistant.formality"
            :class="selectClasses"
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
        </div>
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.EMPATHY_LEVEL.LABEL') }}
          </label>
          <select
            :value="assistant.empathy_level"
            :class="selectClasses"
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
        </div>
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.VERBOSITY.LABEL') }}
          </label>
          <select
            :value="assistant.verbosity"
            :class="selectClasses"
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
        </div>
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.EMOJI_USAGE.LABEL') }}
          </label>
          <select
            :value="assistant.emoji_usage"
            :class="selectClasses"
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
        </div>
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.LANGUAGE.LABEL') }}
          </label>
          <select
            :value="assistant.language"
            :class="selectClasses"
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
        </div>
        <div class="md:col-span-2">
          <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.PERSONALITY_DESCRIPTION.LABEL') }}
          </label>
          <textarea
            :value="assistant.personality_description"
            :placeholder="$t('ALOO.FORM.PERSONALITY_DESCRIPTION.PLACEHOLDER')"
            rows="4"
            class="w-full px-3 py-2 text-sm border rounded-lg resize-none border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            @input="updateField('personality_description', $event.target.value)"
          />
        </div>
      </div>
      <div class="pt-4">
        <Button :is-loading="isSaving" @click="emit('save')">
          {{ $t('ALOO.ACTIONS.SAVE') }}
        </Button>
      </div>
    </SettingsSection>
  </div>
</template>
