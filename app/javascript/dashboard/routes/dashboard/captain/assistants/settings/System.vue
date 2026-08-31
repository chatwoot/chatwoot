<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAssistantSettings } from './useAssistantSettings';
import SettingsPageLayout from 'dashboard/components-next/captain/pageComponents/assistant/settings/SettingsPageLayout.vue';
import AssistantSystemSettingsForm from 'dashboard/components-next/captain/pageComponents/assistant/settings/AssistantSystemSettingsForm.vue';

const { t } = useI18n();
const { isCloudFeatureEnabled } = useAccount();
const { assistantId, assistant, fetchAssistant, updateAssistant } =
  useAssistantSettings();
const systemAssistant = ref(assistant.value);

const systemSettingsDescription = computed(() =>
  isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_V2)
    ? t('CAPTAIN.ASSISTANTS.SETTINGS.SYSTEM_SETTINGS.DESCRIPTION_V2')
    : t('CAPTAIN.ASSISTANTS.SETTINGS.SYSTEM_SETTINGS.DESCRIPTION')
);

const loadAssistant = async selectedAssistantId => {
  systemAssistant.value =
    assistant.value?.id === selectedAssistantId ? assistant.value : null;

  try {
    const loadedAssistant = await fetchAssistant();
    if (loadedAssistant && assistantId.value === selectedAssistantId) {
      systemAssistant.value = loadedAssistant;
    }
  } catch {
    if (assistantId.value === selectedAssistantId) {
      useAlert(t('CAPTAIN.ASSISTANTS.SETTINGS.SYSTEM_SETTINGS.LOAD_ERROR'));
    }
  }
};

const saveAssistant = async values => {
  const selectedAssistantId = assistantId.value;
  const savedAssistant = await updateAssistant(values);
  if (savedAssistant && assistantId.value === selectedAssistantId) {
    systemAssistant.value = savedAssistant;
  }
};

watch(assistantId, loadAssistant, { immediate: true });
watch(assistant, cachedAssistant => {
  if (!systemAssistant.value && cachedAssistant?.id === assistantId.value) {
    systemAssistant.value = cachedAssistant;
  }
});
</script>

<template>
  <SettingsPageLayout
    :heading="t('CAPTAIN.ASSISTANTS.SETTINGS.SYSTEM_SETTINGS.TITLE')"
    :description="systemSettingsDescription"
  >
    <AssistantSystemSettingsForm
      v-if="systemAssistant?.id === assistantId"
      :assistant="systemAssistant"
      @submit="saveAssistant"
    />
  </SettingsPageLayout>
</template>
