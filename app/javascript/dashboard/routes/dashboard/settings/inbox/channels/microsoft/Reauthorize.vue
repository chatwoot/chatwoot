<script setup>
import { ref } from 'vue';
import InboxReconnectionRequired from '../../components/InboxReconnectionRequired';
import microsoftClient from 'dashboard/api/channel/microsoftClient';

import { useI18n } from 'dashboard/composables/useI18n';
import { useAlert } from 'dashboard/composables';

const { t } = useI18n();

const props = defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

const isRequestingAuthorization = ref(false);

async function requestAuthorization() {
  try {
    isRequestingAuthorization.value = true;
    const response = await microsoftClient.generateAuthorization({
      email: props.inbox.email,
    });

    const {
      data: { url },
    } = response;
    window.location.href = url;
  } catch (error) {
    useAlert(t('INBOX_MGMT.ADD.MICROSOFT.ERROR_MESSAGE'));
  } finally {
    isRequestingAuthorization.value = false;
  }
}
</script>

<template>
  <inbox-reconnection-required
    class="mx-8 mt-5"
    @reauthorize="requestAuthorization"
  />
</template>
