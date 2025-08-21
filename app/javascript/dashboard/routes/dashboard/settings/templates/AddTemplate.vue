<script setup>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import NextButton from 'dashboard/components-next/button/Button.vue';
import { createTemplate } from './helpers/templatesHelper';

const emit = defineEmits(['close']);

const { t } = useI18n();

const templateName = ref('');
const selectedLanguage = ref('English (en-US)');
const selectedContentType = ref('Text');
const isLoading = ref(false);

const contentTypes = [
  { value: 'Text', label: 'Text', icon: 'i-lucide-type' },
  { value: 'Media', label: 'Media', icon: 'i-lucide-image' },
  { value: 'Quick reply', label: 'Quick reply', icon: 'i-lucide-zap' },
];

const callToActionTypes = [
  {
    value: 'Call to action',
    label: 'Call to action',
    icon: 'i-lucide-phone-call',
  },
  { value: 'List picker', label: 'List picker', icon: 'i-lucide-list' },
  { value: 'Card', label: 'Card', icon: 'i-lucide-credit-card' },
];

const whatsappCardTypes = [
  {
    value: 'WhatsApp Card',
    label: 'WhatsApp Card',
    icon: 'i-lucide-message-circle',
  },
  { value: 'Catalog', label: 'Catalog', icon: 'i-lucide-book-open' },
  {
    value: 'Authentication',
    label: 'Authentication',
    icon: 'i-lucide-shield-check',
  },
  { value: 'Carousel', label: 'Carousel', icon: 'i-lucide-gallery-horizontal' },
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

const isFormValid = computed(() => {
  return !v$.value.$invalid && templateName.value.trim().length > 0;
});

const onClose = () => {
  emit('close');
};

const handleCreate = async () => {
  if (!isFormValid.value) return;

  isLoading.value = true;
  try {
    const templateData = {
      name: templateName.value.trim(),
      language: selectedLanguage.value,
      content_type: selectedContentType.value,
      category: 'general',
      channel_type: 'whatsapp',
      status: 'pending',
      content: `New template: ${templateName.value}`,
    };

    await createTemplate(templateData);
    useAlert(t('SETTINGS.TEMPLATES.API.SUCCESS_MESSAGE'));
    onClose();
  } catch (error) {
    useAlert(t('SETTINGS.TEMPLATES.API.ERROR_MESSAGE'));
  } finally {
    isLoading.value = false;
  }
};

const selectContentType = type => {
  selectedContentType.value = type;
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto max-w-md w-full">
    <woot-modal-header
      :header-title="$t('SETTINGS.TEMPLATES.ADD.TITLE')"
      :header-content="$t('SETTINGS.TEMPLATES.ADD.DESC')"
    />

    <form
      class="flex flex-col w-full p-6 space-y-6"
      @submit.prevent="handleCreate"
    >
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
          :class="{ 'border-red-500': v$.templateName.$error }"
          @blur="v$.templateName.$touch"
        />
        <span v-if="v$.templateName.$error" class="text-xs text-red-500 mt-1">
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.NAME.ERROR') }}
        </span>
      </div>

      <!-- Language -->
      <div class="w-full">
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.LANGUAGE.LABEL') }}
        </label>
        <select
          v-model="selectedLanguage"
          class="w-full px-3 py-2 border border-n-weak rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-5 focus:border-n-blue-5"
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

      <!-- Content Type -->
      <div class="w-full">
        <label class="block text-sm font-medium text-n-slate-12 mb-3">
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.CONTENT_TYPE.LABEL') }}
        </label>

        <!-- Content Type Buttons -->
        <div class="grid grid-cols-3 gap-2 mb-4">
          <button
            v-for="type in contentTypes"
            :key="type.value"
            type="button"
            class="flex flex-col items-center p-3 border rounded-lg transition-colors"
            :class="
              selectedContentType === type.value
                ? 'border-n-blue-5 bg-n-blue-1 text-n-blue-text'
                : 'border-n-weak bg-n-solid-1 text-n-slate-11 hover:bg-n-solid-2'
            "
            @click="selectContentType(type.value)"
          >
            <span :class="type.icon" class="size-5 mb-2" />
            <span class="text-xs font-medium">{{ type.label }}</span>
          </button>
        </div>

        <!-- Call to Action Row -->
        <div class="grid grid-cols-3 gap-2 mb-4">
          <button
            v-for="type in callToActionTypes"
            :key="type.value"
            type="button"
            class="flex flex-col items-center p-3 border rounded-lg transition-colors border-n-weak bg-n-solid-1 text-n-slate-11 hover:bg-n-solid-2"
            @click="selectContentType(type.value)"
          >
            <span :class="type.icon" class="size-5 mb-2" />
            <span class="text-xs font-medium">{{ type.label }}</span>
          </button>
        </div>

        <!-- WhatsApp Card Row -->
        <div class="grid grid-cols-2 gap-2">
          <button
            v-for="type in whatsappCardTypes"
            :key="type.value"
            type="button"
            class="flex flex-col items-center p-3 border rounded-lg transition-colors border-n-weak bg-n-solid-1 text-n-slate-11 hover:bg-n-solid-2"
            @click="selectContentType(type.value)"
          >
            <span :class="type.icon" class="size-5 mb-2" />
            <span class="text-xs font-medium">{{ type.label }}</span>
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
          type="submit"
          :label="$t('SETTINGS.TEMPLATES.ADD.CREATE')"
          :disabled="!isFormValid || isLoading"
          :is-loading="isLoading"
        />
      </div>
    </form>
  </div>
</template>
