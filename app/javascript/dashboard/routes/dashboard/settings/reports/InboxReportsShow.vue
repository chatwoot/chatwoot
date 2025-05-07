<script setup>
import { useRoute } from 'vue-router';
import { useFunctionGetter } from 'dashboard/composables/store';
import { computed, watch } from 'vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

import WootReports from './components/WootReports.vue';
import VoiceInboxReports from './VoiceInboxReports.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const route = useRoute();
const inbox = useFunctionGetter('inboxes/getInboxById', route.params.id);

// No special parameters needed - only show voice reports for actual voice channels

// Determine if this is a voice channel
const isVoiceChannel = computed(() => {
  // If inbox data isn't loaded yet, return false
  if (!inbox.value) return false;
  
  // Log for debugging purposes
  console.log('Inbox data for voice check:', inbox.value);
  console.log('Channel type (camelCase):', inbox.value.channelType);
  console.log('Expected channel type:', INBOX_TYPES.VOICE);
  
  // Check against the channelType property (camelCase)
  return inbox.value.channelType === INBOX_TYPES.VOICE;
});
</script>

<template>
  <VoiceInboxReports
    v-if="inbox.id && isVoiceChannel"
    :key="inbox.id"
  />
  <WootReports
    v-else-if="inbox.id"
    :key="inbox.id"
    type="inbox"
    getter-key="inboxes/getInboxes"
    action-key="inboxes/get"
    :selected-item="inbox"
    :download-button-label="$t('INBOX_REPORTS.DOWNLOAD_INBOX_REPORTS')"
    :report-title="$t('INBOX_REPORTS.HEADER')"
    has-back-button
  />
  <div v-else class="w-full py-20">
    <Spinner class="mx-auto" />
  </div>
</template>
