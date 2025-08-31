<script setup>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';

import NextButton from 'dashboard/components-next/button/Button.vue';
import { validateTemplateName } from './helpers/templateValidation';

const emit = defineEmits(['close']);

const { t } = useI18n();
const router = useRouter();

const templateName = ref('');
const selectedLanguage = ref('English (en-US)');
const selectedChannelType = ref('whatsapp');

const channelTypes = [
  { value: 'whatsapp', label: 'WhatsApp', icon: 'i-lucide-message-circle' },
];

const languageOptions = [
  { value: 'English (en-US)', label: 'English (en-US)' },
];

const validationRules = {
  templateName: {
    required,
    minLength: minLength(2),
  },
};

const v$ = useVuelidate(validationRules, {
  templateName,
});

const isBasicFormValid = computed(() => {
  return !v$.value.$invalid && templateName.value.trim().length > 0;
});

const nameValidation = computed(() => {
  if (!templateName.value) return { isValid: true, errors: [] };
  return validateTemplateName(templateName.value);
});

const onClose = () => {
  emit('close');
};

const goToBuilder = () => {
  if (isBasicFormValid.value && nameValidation.value.isValid) {
    // Navigate to builder page with template info as query params
    router.push({
      name: 'template_builder',
      query: {
        name: templateName.value.trim(),
        language: selectedLanguage.value,
        channelType: selectedChannelType.value,
      },
    });
    onClose();
  }
};

const selectChannelType = type => {
  selectedChannelType.value = type;
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto w-full">
    <!-- Header -->
    <div class="px-6 py-4 border-b border-n-weak">
      <h2 class="text-lg font-semibold text-n-slate-12 mb-1">
        {{ $t('SETTINGS.TEMPLATES.ADD.TITLE') }}
      </h2>
      <p class="text-sm text-n-slate-11">
        {{ $t('SETTINGS.TEMPLATES.ADD.DESC') }}
      </p>
    </div>

    <!-- Basic Information Form -->
    <div class="flex flex-col w-full p-6 space-y-4">
      <!-- Template Name -->
      <div class="w-full">
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.NAME.LABEL') }}
        </label>
        <input
          v-model="templateName"
          type="text"
          :placeholder="$t('SETTINGS.TEMPLATES.ADD.FORM.NAME.PLACEHOLDER')"
          class="w-full px-3 py-2 border border-n-weak rounded-lg bg-n-solid-1 text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-5 focus:border-n-blue-5"
          :class="{
            'border-red-500': v$.templateName.$error || !nameValidation.isValid,
          }"
          @blur="v$.templateName.$touch"
        />
        <span
          v-if="v$.templateName.$error"
          class="text-xs text-red-500 mt-1 block"
        >
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.NAME.ERROR') }}
        </span>
        <span
          v-if="!nameValidation.isValid"
          class="text-xs text-red-500 mt-1 block"
        >
          {{ nameValidation.errors[0] }}
        </span>
        <span
          v-if="
            !v$.templateName.$error && nameValidation.isValid && templateName
          "
          class="text-xs text-n-slate-11 mt-1 block"
        >
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.NAME.HELP') }}
        </span>
      </div>

      <!-- Language -->
      <div class="w-full">
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.LANGUAGE.LABEL') }}
        </label>
        <select
          v-model="selectedLanguage"
          class="w-full px-3 py-2 border border-n-weak rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-5 focus:border-n-blue-5 pr-8"
        >
          <option
            v-for="lang in languageOptions"
            :key="lang.value"
            :value="lang.value"
          >
            {{ lang.label }}
          </option>
        </select>
      </div>

      <!-- Channel Type -->
      <div class="w-full">
        <label class="block text-sm font-medium text-n-slate-12 mb-3">
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.CHANNEL_TYPE.LABEL') }}
        </label>

        <!-- Channel Type Buttons -->
        <div class="grid grid-cols-1 gap-2">
          <button
            v-for="type in channelTypes"
            :key="type.value"
            type="button"
            class="flex items-center p-3 border rounded-lg transition-colors"
            :class="
              selectedChannelType === type.value
                ? 'border-n-blue-5 bg-n-blue-1 text-n-blue-text'
                : 'border-n-weak bg-n-solid-1 text-n-slate-12 hover:bg-n-solid-2 hover:border-n-strong'
            "
            @click="selectChannelType(type.value)"
          >
            <span :class="type.icon" class="size-5 mr-3" />
            <span class="text-sm font-medium">{{ type.label }}</span>
          </button>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="flex flex-row justify-end w-full gap-3 pt-4">
        <NextButton
          faded
          slate
          :label="$t('SETTINGS.TEMPLATES.ADD.CANCEL')"
          @click="onClose"
        />
        <NextButton
          :label="$t('SETTINGS.TEMPLATES.ADD.CONTINUE')"
          :disabled="!isBasicFormValid || !nameValidation.isValid"
          @click="goToBuilder"
        />
      </div>
    </div>
  </div>
</template>
