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

const greetingStyleOptions = computed(() => [
  { value: 'warm', label: t('ALOO.FORM.GREETING_STYLE.OPTIONS.WARM') },
  { value: 'direct', label: t('ALOO.FORM.GREETING_STYLE.OPTIONS.DIRECT') },
  { value: 'custom', label: t('ALOO.FORM.GREETING_STYLE.OPTIONS.CUSTOM') },
]);

const showCustomGreeting = computed(
  () => props.assistant.greeting_style === 'custom'
);
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
          {{ $t('ALOO.FORM.GREETING_STYLE.LABEL') }}
          <select
            :value="assistant.greeting_style"
            @change="updateField('greeting_style', $event.target.value)"
          >
            <option
              v-for="option in greetingStyleOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>
        <label v-if="showCustomGreeting" class="md:col-span-2">
          {{ $t('ALOO.FORM.CUSTOM_GREETING.LABEL') }}
          <textarea
            :value="assistant.custom_greeting"
            :placeholder="$t('ALOO.FORM.CUSTOM_GREETING.PLACEHOLDER')"
            rows="2"
            @input="updateField('custom_greeting', $event.target.value)"
          />
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
