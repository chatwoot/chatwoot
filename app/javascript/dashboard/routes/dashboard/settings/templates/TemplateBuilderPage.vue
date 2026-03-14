<script setup>
import { computed, onMounted, onUnmounted, onDeactivated, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import TemplateBuilder from './TemplateBuilder.vue';

const { t } = useI18n();
const router = useRouter();
const store = useStore();

const templateBuilderRef = ref(null);

const isTemplateBuilderValid = computed(() => {
  return !!templateBuilderRef.value?.isValidTemplate;
});

const isEditMode = computed(() => {
  const config = store.getters['messageTemplates/getBuilderConfig'];
  return !!config?.templateId;
});

const isLoading = computed(() => {
  const uiFlags = store.getters['messageTemplates/getUIFlags'];
  return uiFlags.isCreating || uiFlags.isUpdating;
});

const goBack = () => {
  router.push({ name: 'templates_list' });
};

const resetBuilderState = () => {
  templateBuilderRef.value?.resetBuilderState();
  store.dispatch('messageTemplates/resetBuilderConfig');
};

const handleSave = async () => {
  if (!isTemplateBuilderValid.value) return;

  try {
    const templateConfig = store.getters['messageTemplates/getBuilderConfig'];
    const components = templateBuilderRef.value.generateComponents();

    const templateData = {
      name: templateConfig.name,
      language: templateConfig.language,
      category: templateConfig.category,
      channel_type: templateConfig.channelType,
      inbox_id: templateConfig.inboxId,
      parameter_format: templateBuilderRef.value.parameterType,
      content: {
        components,
      },
    };

    await store.dispatch('messageTemplates/create', templateData);
    useAlert(t('SETTINGS.TEMPLATES.API.SUCCESS_MESSAGE'));

    goBack();
  } catch (error) {
    useAlert(t('SETTINGS.TEMPLATES.API.ERROR_MESSAGE'));
  }
};

onMounted(() => {
  const config = store.getters['messageTemplates/getBuilderConfig'];
  if (!config.name) {
    router.push({ name: 'templates_list' });
  }
});

onDeactivated(resetBuilderState);
onUnmounted(resetBuilderState);
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
          {{
            isEditMode
              ? t('SETTINGS.TEMPLATES.BUILDER.EDIT_TEMPLATE')
              : t('SETTINGS.TEMPLATES.BUILDER.BUILD_TEMPLATE')
          }}
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
          <TemplateBuilder ref="templateBuilderRef" />
        </div>
      </div>
    </div>
  </div>
</template>
