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
const showAddInput = ref(false);
const addHandle = ref('');
const addError = ref('');

const isAdding = computed(
  () => store.getters['influencerProfiles/getUIFlags'].isAdding
);

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

async function handleAddByHandle() {
  if (!addHandle.value.trim()) return;
  addError.value = '';
  try {
    const data = await store.dispatch('influencerProfiles/addByHandle', {
      handle: addHandle.value.trim(),
    });
    addHandle.value = '';
    showAddInput.value = false;
    if (data.existing) {
      addError.value = t('INFLUENCER.ADD.EXISTS');
    }
  } catch {
    addError.value = t('INFLUENCER.ADD.ERROR');
  }
}

async function handleDelete() {
  if (!selectedProfile.value) return;
  // eslint-disable-next-line no-alert
  if (!window.confirm(t('INFLUENCER.DELETE.CONFIRM'))) return;
  await store.dispatch('influencerProfiles/deleteProfile', {
    id: selectedProfile.value.id,
    status: selectedProfile.value.status,
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
      <div class="ml-auto flex items-center gap-2">
        <template v-if="showAddInput">
          <input
            v-model="addHandle"
            type="text"
            class="w-64 rounded-lg border border-n-weak bg-n-solid-1 px-3 py-1.5 text-sm"
            :placeholder="t('INFLUENCER.ADD.PLACEHOLDER')"
            :disabled="isAdding"
            @keydown.enter="handleAddByHandle"
            @keydown.escape="showAddInput = false"
          />
          <button
            class="rounded-lg bg-n-brand px-3 py-1.5 text-sm font-medium text-white hover:opacity-90 disabled:opacity-50"
            :disabled="isAdding || !addHandle.trim()"
            @click="handleAddByHandle"
          >
            <span
              v-if="isAdding"
              class="i-lucide-loader-2 size-4 animate-spin"
            />
            <template v-else>{{ t('INFLUENCER.ADD.BUTTON') }}</template>
          </button>
          <button
            class="rounded-md p-1 text-n-slate-11 hover:bg-n-background"
            @click="showAddInput = false"
          >
            <span class="i-lucide-x size-4" />
          </button>
        </template>
        <button
          v-else
          class="rounded-md p-1 text-n-slate-11 hover:bg-n-background"
          :title="t('INFLUENCER.ADD.BUTTON')"
          @click="showAddInput = true"
        >
          <span class="i-lucide-plus size-5" />
        </button>
      </div>
      <p v-if="addError" class="text-xs text-red-600">{{ addError }}</p>
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
      @delete="handleDelete"
      @update:profile="p => (selectedProfile = p)"
    />
  </div>
</template>
