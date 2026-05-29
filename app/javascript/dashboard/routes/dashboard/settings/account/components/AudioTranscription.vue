<script setup>
import { useI18n } from 'vue-i18n';
import AccountSettingToggle from './AccountSettingToggle.vue';

const { t } = useI18n();
</script>

<template>
  <AccountSettingToggle
    setting-key="audio_transcriptions"
    :title="t('GENERAL_SETTINGS.FORM.AUDIO_TRANSCRIPTION.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.AUDIO_TRANSCRIPTION.NOTE')"
    :success-message="
      t('GENERAL_SETTINGS.FORM.AUDIO_TRANSCRIPTION.API.SUCCESS')
    "
    :error-message="t('GENERAL_SETTINGS.FORM.AUDIO_TRANSCRIPTION.API.ERROR')"
  />
</template>
