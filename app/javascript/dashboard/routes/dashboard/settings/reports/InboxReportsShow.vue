<script setup>
import WootReports from './components/WootReports.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const hasBackButton = true;
import { useRoute } from 'vue-router';
const route = useRoute();

import { useStoreGetters } from 'dashboard/composables/store';
import { computed } from 'vue';
const getters = useStoreGetters();

const inbox = computed(() =>
  getters['inboxes/getInboxById'].value(route.params.inboxId)
);
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
    :has-back-button
  />
  <Spinner v-else />
</template>
