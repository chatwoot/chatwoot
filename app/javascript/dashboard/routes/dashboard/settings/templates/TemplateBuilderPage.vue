<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';

import NextButton from 'dashboard/components-next/button/Button.vue';
import TemplateBuilder from './TemplateBuilder.vue';
import { createTemplate, updateTemplate } from './helpers/templatesHelper';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const isLoading = ref(false);
const templateBuilderData = ref(null);
const isEditMode = ref(false);
const templateId = ref(null);

// Template basic info from route params or localStorage
const templateName = ref('');
const selectedLanguage = ref('English (en-US)');
const selectedChannelType = ref('whatsapp');

const isTemplateBuilderValid = computed(() => {
  return templateBuilderData.value && templateBuilderData.value.isValid;
});

const handleTemplateUpdate = builderData => {
  templateBuilderData.value = builderData;
};

const goBack = () => {
  router.push({ name: 'templates_list' });
};

const handleSave = async () => {
  if (!isTemplateBuilderValid.value) return;

  isLoading.value = true;
  try {
    const templateData = {
      name: templateName.value.trim(),
      language: selectedLanguage.value,
      category: 'general',
      channel_type: selectedChannelType.value,
      status: 'pending',
      content: templateBuilderData.value.content,
      components: templateBuilderData.value.components,
    };

    if (isEditMode.value) {
      await updateTemplate(templateId.value, templateData);
      useAlert(t('SETTINGS.TEMPLATES.API.UPDATE_SUCCESS'));
    } else {
      await createTemplate(templateData);
      useAlert(t('SETTINGS.TEMPLATES.API.SUCCESS_MESSAGE'));
    }

    goBack();
  } catch (error) {
    useAlert(t('SETTINGS.TEMPLATES.API.ERROR_MESSAGE'));
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  // Get template info from route query params
  if (route.query.name) {
    templateName.value = route.query.name;
  }
  if (route.query.language) {
    selectedLanguage.value = route.query.language;
  }
  if (route.query.channelType) {
    selectedChannelType.value = route.query.channelType;
  }
  if (route.query.id) {
    templateId.value = route.query.id;
    isEditMode.value = true;
  }

  // Fallback to localStorage if no query params
  if (!templateName.value) {
    const storedData = localStorage.getItem('chatwoot_template_basic_info');
    if (storedData) {
      const parsed = JSON.parse(storedData);
      templateName.value = parsed.name || '';
      selectedLanguage.value = parsed.language || 'English (en-US)';
      selectedChannelType.value = parsed.channelType || 'whatsapp';
      localStorage.removeItem('chatwoot_template_basic_info');
    }
  }
});
</script>

<template>
  <div class="flex flex-col h-full w-full">
    <!-- Header -->
    <div
      class="flex items-center justify-between px-6 py-4 border-b border-slate-700"
    >
      <!-- Breadcrumb -->
      <div class="flex items-center gap-3">
        <button
          type="button"
          class="text-slate-300 hover:text-white text-sm font-medium"
          @click="goBack"
        >
          {{ t('SETTINGS.TEMPLATES.HEADER.TITLE') }}
        </button>
        <span class="i-lucide-chevron-right size-4 text-slate-500" />
        <span class="text-sm text-slate-300">
          {{ isEditMode ? 'Edit template' : 'Build template' }}
        </span>
      </div>

      <!-- Action Buttons -->
      <div class="flex items-center gap-3">
        <NextButton slate faded label="Discard" @click="goBack" />
        <NextButton
          blue
          label="Save template"
          :disabled="!isTemplateBuilderValid || isLoading"
          :is-loading="isLoading"
          @click="handleSave"
        />
      </div>
    </div>

    <!-- Main Content -->
    <div class="flex flex-1">
      <!-- Builder Panel -->
      <div class="flex-1 py-12 px-16">
        <div class="max-w-5xl mx-auto">
          <TemplateBuilder @update:template="handleTemplateUpdate" />
        </div>
      </div>
    </div>
  </div>
</template>
