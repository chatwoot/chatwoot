<script setup>
import { ref } from 'vue';
import InboxReconnectionRequired from '../../components/InboxReconnectionRequired.vue';

import xClient from 'dashboard/api/channel/xClient';

import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

const { t } = useI18n();

const isRequestingAuthorization = ref(false);

async function requestAuthorization() {
  try {
    isRequestingAuthorization.value = true;
    const response = await xClient.generateAuthorization();

    const {
      data: { authorization_url: url },
    } = response;

    window.location.href = url;
  } catch (error) {
    useAlert(t('INBOX_MGMT.ADD.X.ERROR_AUTH'));
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
