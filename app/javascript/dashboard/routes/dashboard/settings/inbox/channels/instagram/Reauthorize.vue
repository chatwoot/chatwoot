<script setup>
import { ref } from 'vue';
import InboxReconnectionRequired from '../../components/InboxReconnectionRequired.vue';

import instagramClient from 'dashboard/api/channel/instagramClient';

import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

const { t } = useI18n();

const isRequestingAuthorization = ref(false);

async function requestAuthorization() {
  try {
    isRequestingAuthorization.value = true;
    const response = await instagramClient.generateAuthorization();

    const {
      data: { url },
    } = response;

    window.location.href = url;
  } catch (error) {
    useAlert(t('INBOX_MGMT.ADD.INSTAGRAM.ERROR_AUTH'));
  } finally {
    isRequestingAuthorization.value = false;
  }
}
</script>

<template>
  <InboxReconnectionRequired
    class="mx-8 mt-5"
    @reauthorize="requestAuthorization"
  />
</template>
