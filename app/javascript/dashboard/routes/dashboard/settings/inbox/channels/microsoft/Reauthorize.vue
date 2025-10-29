<script setup>
import { ref } from 'vue';
import InboxReconnectionRequired from '../../components/InboxReconnectionRequired.vue';
import microsoftClient from 'dashboard/api/channel/microsoftClient';

import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();

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
  <InboxReconnectionRequired
    class="mx-8 mt-5"
    @reauthorize="requestAuthorization"
  />
</template>
