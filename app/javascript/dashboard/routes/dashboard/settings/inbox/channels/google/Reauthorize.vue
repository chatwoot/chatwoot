<script setup>
import { ref, computed } from 'vue';
import InboxReconnectionRequired from '../../components/InboxReconnectionRequired.vue';
import googleClient from 'dashboard/api/channel/googleClient';

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

const inboxEmail = computed(() => {
  if (props.inbox.imap_login && props.inbox.imap_enabled) {
    return props.inbox.imap_login;
  }
  return props.inbox.email;
});

async function requestAuthorization() {
  try {
    isRequestingAuthorization.value = true;
    const response = await googleClient.generateAuthorization({
      email: inboxEmail.value,
    });

    const {
      data: { url },
    } = response;
    window.location.href = url;
  } catch (error) {
    useAlert(t('INBOX_MGMT.ADD.GOOGLE.ERROR_MESSAGE'));
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
