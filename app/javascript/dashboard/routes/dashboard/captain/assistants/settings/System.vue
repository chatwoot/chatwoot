<script setup>
import { useI18n } from 'vue-i18n';
import { useAssistantSettings } from './useAssistantSettings';
import SettingsPageLayout from 'dashboard/components-next/captain/pageComponents/assistant/settings/SettingsPageLayout.vue';
import AssistantSystemSettingsForm from 'dashboard/components-next/captain/pageComponents/assistant/settings/AssistantSystemSettingsForm.vue';

const { t } = useI18n();
const { assistant, updateAssistant } = useAssistantSettings();
</script>

<template>
  <SettingsPageLayout
    :heading="t('CAPTAIN.ASSISTANTS.SETTINGS.SYSTEM_SETTINGS.TITLE')"
    :description="t('CAPTAIN.ASSISTANTS.SETTINGS.SYSTEM_SETTINGS.DESCRIPTION')"
  >
    <AssistantSystemSettingsForm
      :assistant="assistant"
      @submit="updateAssistant"
    />
  </SettingsPageLayout>
</template>
