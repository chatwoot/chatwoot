<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useStore, useStoreGetters } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const getters = useStoreGetters();
const { accountScopedRoute } = useAccount();

const wizardData = computed(() => getters['alooWizard/getWizardData'].value);

const createField = field =>
  computed({
    get: () => wizardData.value[field],
    set: val => store.dispatch('alooWizard/updateField', { field, value: val }),
  });

const tone = createField('tone');
const formality = createField('formality');
const empathy_level = createField('empathy_level');
const verbosity = createField('verbosity');
const emoji_usage = createField('emoji_usage');
const greeting_style = createField('greeting_style');
const custom_greeting = createField('custom_greeting');
const language = createField('language');
const dialect = createField('dialect');
const personality_description = createField('personality_description');

const toneOptions = [
  { value: 'professional', label: t('ALOO.FORM.TONE.OPTIONS.PROFESSIONAL') },
  { value: 'friendly', label: t('ALOO.FORM.TONE.OPTIONS.FRIENDLY') },
  { value: 'casual', label: t('ALOO.FORM.TONE.OPTIONS.CASUAL') },
  { value: 'formal', label: t('ALOO.FORM.TONE.OPTIONS.FORMAL') },
];

const formalityOptions = [
  { value: 'high', label: t('ALOO.FORM.FORMALITY.OPTIONS.HIGH') },
  { value: 'medium', label: t('ALOO.FORM.FORMALITY.OPTIONS.MEDIUM') },
  { value: 'low', label: t('ALOO.FORM.FORMALITY.OPTIONS.LOW') },
];

const empathyOptions = [
  { value: 'high', label: t('ALOO.FORM.EMPATHY_LEVEL.OPTIONS.HIGH') },
  { value: 'medium', label: t('ALOO.FORM.EMPATHY_LEVEL.OPTIONS.MEDIUM') },
  { value: 'low', label: t('ALOO.FORM.EMPATHY_LEVEL.OPTIONS.LOW') },
];

const verbosityOptions = [
  { value: 'concise', label: t('ALOO.FORM.VERBOSITY.OPTIONS.CONCISE') },
  { value: 'balanced', label: t('ALOO.FORM.VERBOSITY.OPTIONS.BALANCED') },
  { value: 'detailed', label: t('ALOO.FORM.VERBOSITY.OPTIONS.DETAILED') },
];

const emojiOptions = [
  { value: 'none', label: t('ALOO.FORM.EMOJI_USAGE.OPTIONS.NONE') },
  { value: 'minimal', label: t('ALOO.FORM.EMOJI_USAGE.OPTIONS.MINIMAL') },
  { value: 'moderate', label: t('ALOO.FORM.EMOJI_USAGE.OPTIONS.MODERATE') },
];

const greetingOptions = [
  { value: 'warm', label: t('ALOO.FORM.GREETING_STYLE.OPTIONS.WARM') },
  { value: 'direct', label: t('ALOO.FORM.GREETING_STYLE.OPTIONS.DIRECT') },
  { value: 'custom', label: t('ALOO.FORM.GREETING_STYLE.OPTIONS.CUSTOM') },
];

const languageOptions = [
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
];

const dialectOptions = [
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
];

const showDialect = computed(() => language.value === 'ar');
const showCustomGreeting = computed(() => greeting_style.value === 'custom');

const goToNext = () => {
  router.push(accountScopedRoute('settings_aloo_new_knowledge'));
};

const goBack = () => {
  router.push(accountScopedRoute('settings_aloo_new'));
};
</script>

<template>
  <div class="flex flex-col h-full p-8 overflow-visible">
    <div class="flex-1 overflow-visible">
      <h2 class="text-xl font-semibold text-n-slate-12 mb-2">
        {{ $t('ALOO.WIZARD.STEP_2') }}
      </h2>
      <p class="text-n-slate-11 mb-8">
        {{ $t('ALOO.WIZARD.STEP_2_DESCRIPTION') }}
      </p>

      <div
        class="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-3xl overflow-visible"
      >
        <!-- Tone -->
        <label class="block overflow-visible">
          <span class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.TONE.LABEL') }}
          </span>
          <select v-model="tone" class="!mb-0">
            <option
              v-for="option in toneOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>

        <!-- Formality -->
        <label class="block">
          <span class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.FORMALITY.LABEL') }}
          </span>
          <select v-model="formality" class="!mb-0">
            <option
              v-for="option in formalityOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>

        <!-- Empathy Level -->
        <label class="block">
          <span class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.EMPATHY_LEVEL.LABEL') }}
          </span>
          <select v-model="empathy_level" class="!mb-0">
            <option
              v-for="option in empathyOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>

        <!-- Verbosity -->
        <label class="block">
          <span class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.VERBOSITY.LABEL') }}
          </span>
          <select v-model="verbosity" class="!mb-0">
            <option
              v-for="option in verbosityOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>

        <!-- Emoji Usage -->
        <label class="block">
          <span class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.EMOJI_USAGE.LABEL') }}
          </span>
          <select v-model="emoji_usage" class="!mb-0">
            <option
              v-for="option in emojiOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>

        <!-- Greeting Style -->
        <label class="block">
          <span class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.GREETING_STYLE.LABEL') }}
          </span>
          <select v-model="greeting_style" class="!mb-0">
            <option
              v-for="option in greetingOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>

        <!-- Language -->
        <label class="block">
          <span class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.LANGUAGE.LABEL') }}
          </span>
          <select v-model="language" class="!mb-0">
            <option
              v-for="option in languageOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>

        <!-- Dialect (Arabic only) -->
        <label v-if="showDialect" class="block">
          <span class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.DIALECT.LABEL') }}
          </span>
          <select v-model="dialect" class="!mb-0">
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

        <!-- Custom Greeting -->
        <div v-if="showCustomGreeting" class="md:col-span-2">
          <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.CUSTOM_GREETING.LABEL') }}
          </label>
          <textarea
            v-model="custom_greeting"
            :placeholder="$t('ALOO.FORM.CUSTOM_GREETING.PLACEHOLDER')"
            rows="3"
            class="w-full px-3 py-2 text-sm border rounded-lg resize-none border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>

        <!-- Personality Description -->
        <div class="md:col-span-2">
          <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.PERSONALITY_DESCRIPTION.LABEL') }}
          </label>
          <textarea
            v-model="personality_description"
            :placeholder="$t('ALOO.FORM.PERSONALITY_DESCRIPTION.PLACEHOLDER')"
            rows="4"
            class="w-full px-3 py-2 text-sm border rounded-lg resize-none border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>
      </div>
    </div>

    <div class="flex justify-between pt-6 border-t border-n-weak">
      <Button variant="faded" slate @click="goBack">
        {{ $t('ALOO.ACTIONS.BACK') }}
      </Button>
      <Button @click="goToNext">
        {{ $t('ALOO.ACTIONS.NEXT') }}
      </Button>
    </div>
  </div>
</template>
