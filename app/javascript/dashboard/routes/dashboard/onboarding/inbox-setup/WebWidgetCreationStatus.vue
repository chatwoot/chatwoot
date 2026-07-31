<script setup>
import { computed } from 'vue';
import { useTimeoutPoll } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import CreationStatusRow from './CreationStatusRow.vue';

const POLL_INTERVAL = 5000;

const { t } = useI18n();
const store = useStore();

// The web widget inbox is created asynchronously during account setup. We poll
// the inboxes endpoint until it shows up, then stop — much simpler than the
// event-driven help center flow.
const websiteInboxes = useMapGetter('inboxes/getWebsiteInboxes');
const isReady = computed(() => websiteInboxes.value.length > 0);

// useTimeoutPoll waits for each fetch to settle before scheduling the next (so
// requests never overlap), fires immediately on mount, and stops on unmount.
const { pause } = useTimeoutPoll(
  async () => {
    await store.dispatch('inboxes/get');
    if (isReady.value) pause();
  },
  POLL_INTERVAL,
  { immediate: true }
);
</script>

<template>
  <CreationStatusRow
    :ready="isReady"
    :title="t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.LIVE_CHAT')"
    :description="
      t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.LIVE_CHAT_DESCRIPTION')
    "
    :status="
      isReady
        ? t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.LIVE_CHAT_READY')
        : t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.LIVE_CHAT_STATUS')
    "
  />
</template>
