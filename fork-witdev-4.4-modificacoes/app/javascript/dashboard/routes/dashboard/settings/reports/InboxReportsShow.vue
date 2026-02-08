<script setup>
import { useRoute } from 'vue-router';
import { useFunctionGetter } from 'dashboard/composables/store';

import WootReports from './components/WootReports.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const route = useRoute();
const inbox = useFunctionGetter('inboxes/getInboxById', route.params.id);
</script>

<template>
  <WootReports
    v-if="inbox.id"
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
