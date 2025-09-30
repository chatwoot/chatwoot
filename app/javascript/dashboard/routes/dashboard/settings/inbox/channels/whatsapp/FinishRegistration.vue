<script setup>
import { useI18n } from 'vue-i18n';
import InboxReconnectionRequired from '../../components/InboxReconnectionRequired.vue';

const { t } = useI18n();

const handleCompleteRegistration = () => {};
</script>

<template>
  <InboxReconnectionRequired
    class="mx-8 mt-5"
    :action-label="t('INBOX_MGMT.COMPLETE_REGISTRATION')"
    :description="t('INBOX_MGMT.WHATSAPP_REGISTRATION_INCOMPLETE')"
    @reauthorize="handleCompleteRegistration"
  />
</template>
