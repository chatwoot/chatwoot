<script setup>
import { useI18n } from 'vue-i18n';
import { useAssistantSettings } from './useAssistantSettings';
import SettingsPageLayout from 'dashboard/components-next/captain/pageComponents/assistant/settings/SettingsPageLayout.vue';
import AssistantAudienceForm from 'dashboard/components-next/captain/pageComponents/assistant/settings/AssistantAudienceForm.vue';

const { t } = useI18n();
const { assistant, updateAssistant } = useAssistantSettings();
</script>

<template>
  <SettingsPageLayout
    :heading="t('CAPTAIN.ASSISTANTS.SETTINGS.AUDIENCE.TITLE')"
    :description="t('CAPTAIN.ASSISTANTS.SETTINGS.AUDIENCE.DESCRIPTION')"
  >
    <AssistantAudienceForm :assistant="assistant" @submit="updateAssistant" />
  </SettingsPageLayout>
</template>
