<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';

import InfluencerSearchPanel from 'dashboard/components-next/Influencers/InfluencerSearchPanel.vue';
import InfluencerSearchResults from 'dashboard/components-next/Influencers/InfluencerSearchResults.vue';
import InfluencerKanbanBoard from 'dashboard/components-next/Influencers/InfluencerKanbanBoard.vue';
import InfluencerProfileDetail from 'dashboard/components-next/Influencers/InfluencerProfileDetail.vue';

const store = useStore();
const route = useRoute();
const { t } = useI18n();

const activeTab = computed(() => {
  const name = route.name;
  if (name === 'influencers_review') return 'review';
  if (name === 'influencers_pipeline') return 'pipeline';
  return 'search';
});

const selectedProfile = ref(null);
const showDetail = ref(false);

const tabs = computed(() => [
  {
    key: 'search',
    label: t('INFLUENCER.TABS.SEARCH'),
    route: 'influencers_search',
  },
  {
    key: 'review',
    label: t('INFLUENCER.TABS.REVIEW'),
    route: 'influencers_review',
  },
  {
    key: 'pipeline',
    label: t('INFLUENCER.TABS.PIPELINE'),
    route: 'influencers_pipeline',
  },
]);

function openProfile(profile) {
  selectedProfile.value = profile;
  showDetail.value = true;
}

function closeDetail() {
  showDetail.value = false;
  selectedProfile.value = null;
}

async function handleApprove(profileId) {
  await store.dispatch('influencerProfiles/approve', { id: profileId });
  closeDetail();
}

async function handleRequestReport(profileId) {
  await store.dispatch('influencerProfiles/requestReport', {
    id: profileId,
  });
  closeDetail();
}

async function handleReject(profileId, reason) {
  const previousStatus = selectedProfile.value?.status;
  await store.dispatch('influencerProfiles/reject', {
    id: profileId,
    reason,
    previousStatus,
  });
  closeDetail();
}
</script>

<template>
  <div class="flex h-full flex-col">
    <div class="flex items-center gap-2 border-b border-n-weak px-6 py-3">
      <h1 class="text-lg font-semibold text-n-slate-12">
        {{ t('INFLUENCER.TITLE') }}
      </h1>
    </div>

    <div class="flex gap-1 border-b border-n-weak px-6">
      <router-link
        v-for="tab in tabs"
        :key="tab.key"
        :to="{ name: tab.route }"
        class="px-3 py-2 text-sm font-medium transition-colors"
        :class="
          activeTab === tab.key
            ? 'border-b-2 border-n-brand text-n-brand'
            : 'text-n-slate-11 hover:text-n-slate-12'
        "
      >
        {{ tab.label }}
      </router-link>
    </div>

    <div class="flex-1 overflow-auto">
      <template v-if="activeTab === 'search'">
        <InfluencerSearchPanel />
        <InfluencerSearchResults @select="openProfile" />
      </template>

      <InfluencerKanbanBoard
        v-else-if="activeTab === 'review'"
        @select="openProfile"
      />

      <InfluencerKanbanBoard
        v-else-if="activeTab === 'pipeline'"
        :statuses="['accepted']"
        @select="openProfile"
      />
    </div>

    <InfluencerProfileDetail
      v-if="showDetail && selectedProfile"
      :profile="selectedProfile"
      @close="closeDetail"
      @approve="handleApprove"
      @reject="handleReject"
      @request-report="handleRequestReport"
    />
  </div>
</template>
