<script setup>
import { useI18n } from 'vue-i18n';
import AccountSettingToggle from './AccountSettingToggle.vue';

const { t } = useI18n();
</script>

<template>
  <AccountSettingToggle
    setting-key="message_deletion_disabled"
    :title="t('GENERAL_SETTINGS.FORM.MESSAGE_DELETION.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.MESSAGE_DELETION.NOTE')"
    :success-message="t('GENERAL_SETTINGS.FORM.MESSAGE_DELETION.API.SUCCESS')"
    :error-message="t('GENERAL_SETTINGS.FORM.MESSAGE_DELETION.API.ERROR')"
    require-confirmation
    :confirm-title="
      t('GENERAL_SETTINGS.FORM.MESSAGE_DELETION.CONFIRM_ENABLE.TITLE')
    "
    :confirm-button-label="
      t('GENERAL_SETTINGS.FORM.MESSAGE_DELETION.CONFIRM_ENABLE.CONFIRM')
    "
    :confirm-title-when-enabled="
      t('GENERAL_SETTINGS.FORM.MESSAGE_DELETION.CONFIRM_DISABLE.TITLE')
    "
    :confirm-button-label-when-enabled="
      t('GENERAL_SETTINGS.FORM.MESSAGE_DELETION.CONFIRM_DISABLE.CONFIRM')
    "
  />
</template>
