<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { mapGetters } from 'vuex';
import { useStore } from 'vuex';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

import ReportHeader from './components/ReportHeader.vue';
import SummaryReportLink from './components/SummaryReportLink.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const store = useStore();
const inboxes = computed(() => store.getters['inboxes/getInboxes']);
const isLoading = computed(() => store.getters['inboxes/getUIFlags'].isFetching);

// Filter only voice inboxes
const voiceInboxes = computed(() => {
  return inboxes.value.filter(inbox => inbox.channelType === INBOX_TYPES.VOICE);
});

// For debugging
console.log('All inboxes:', inboxes.value);
console.log('Voice inboxes:', voiceInboxes.value);

const fetchInboxes = async () => {
  await store.dispatch('inboxes/get');
};

fetchInboxes();
</script>

<template>
  <div>
    <ReportHeader 
      :header-title="$t('INBOX_REPORTS.VOICE_HEADER')" 
      :header-description="$t('INBOX_REPORTS.VOICE_DESCRIPTION')"
    />
    
    <div v-if="isLoading" class="w-full py-20">
      <Spinner class="mx-auto" />
    </div>
    
    <div v-else-if="voiceInboxes.length === 0" class="flex flex-col items-center justify-center py-10">
      <div class="text-n-slate-8 text-lg">{{ $t('INBOX_REPORTS.NO_VOICE_INBOXES') }}</div>
      <div class="text-n-slate-5 text-sm mt-2">{{ $t('INBOX_REPORTS.CREATE_VOICE_INBOX_PROMPT') }}</div>
    </div>
    
    <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 p-6">
      <SummaryReportLink
        v-for="inbox in voiceInboxes"
        :key="inbox.id"
        :name="inbox.name"
        :id="inbox.id"
        type="inbox"
        :avatar-path="'/assets/images/channels/voice.png'"
        :icon-class="'i-ph-phone-fill'"
      />
    </div>
  </div>
</template>