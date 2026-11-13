<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue';
import { storeToRefs } from 'pinia';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useDebounceFn } from '@vueuse/core';
import { useAlert } from 'dashboard/composables';
import { useCompaniesPaywall } from 'dashboard/composables/useCompaniesPaywall';

import Button from 'dashboard/components-next/button/Button.vue';
import DetailsPageLayout from 'dashboard/components-next/DetailsPageLayout.vue';
import Paywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import CompanyConversationFilters from 'dashboard/components-next/Companies/CompanyDetail/CompanyConversationFilters.vue';
import CompanyConversationList from 'dashboard/components-next/Companies/CompanyDetail/CompanyConversationList.vue';
import CompanyNotesFeed from 'dashboard/components-next/Companies/CompanyDetail/CompanyNotesFeed.vue';
import CompanyAddContact from 'dashboard/components-next/Companies/CompanyDetail/CompanyAddContact.vue';
import CompanyDetailHeader from 'dashboard/components-next/Companies/CompanyDetail/CompanyDetailHeader.vue';
import CompanyEditPanel from 'dashboard/components-next/Companies/CompanyDetail/CompanyEditPanel.vue';
import CompanyFacts from 'dashboard/components-next/Companies/CompanyDetail/CompanyFacts.vue';
import CompanySearchInput from 'dashboard/components-next/Companies/CompanySearchInput.vue';
import CompanyPeopleList from 'dashboard/components-next/Companies/CompanyDetail/CompanyPeopleList.vue';
import ConfirmCompanyDeleteDialog from 'dashboard/components-next/Companies/CompanyDetail/ConfirmCompanyDeleteDialog.vue';
import { useCompaniesStore } from 'dashboard/stores/companies';

const route = useRoute();
const router = useRouter();
const companiesStore = useCompaniesStore();
const { t } = useI18n();

const confirmDeleteDialogRef = ref(null);
const editDialogRef = ref(null);
const selectedCandidate = ref(null);
const peopleDialogRef = ref(null);
const layoutRef = ref(null);
const TAB_VALUES = ['conversations', 'notes', 'people'];
const activeTab = computed(() =>
  TAB_VALUES.includes(route.query.tab) ? route.query.tab : TAB_VALUES[0]
);

const companyId = computed(() => Number(route.params.companyId));
const { isReady, showPaywall } = useCompaniesPaywall();
const company = computed(() => companiesStore.getRecord(companyId.value));
const {
  companyConversations,
  companyNotes,
  companyConversationsMeta: conversationsMeta,
  companyNotesMeta: notesMeta,
  contactSearchResults,
  uiFlags,
} = storeToRefs(companiesStore);

const hasCompany = computed(() => Boolean(company.value?.id));
const showInitialLoadingState = computed(
  () =>
    !isReady.value ||
    (!hasCompany.value &&
      (uiFlags.value.fetchingItem || uiFlags.value.fetchingContacts))
);

const hasMoreConversations = computed(
  () =>
    companyConversations.value.length <
    (conversationsMeta.value.totalCount || 0)
);
const hasMoreNotes = computed(
  () => companyNotes.value.length < (notesMeta.value.totalCount || 0)
);

const parseConversationFilters = value => {
  try {
    return value ? JSON.parse(value) : [];
  } catch {
    return [];
  }
};
const conversationFilters = computed({
  get: () =>
    activeTab.value === 'conversations'
      ? parseConversationFilters(route.query.filters)
      : [],
  set: filters => {
    router.replace({
      query: {
        tab: 'conversations',
        filters: filters.length ? JSON.stringify(filters) : undefined,
      },
    });
    companiesStore.getCompanyConversations(companyId.value, 1, filters);
  },
});

const loadMoreConversations = () =>
  companiesStore.getCompanyConversations(
    companyId.value,
    (conversationsMeta.value.page || 1) + 1,
    conversationFilters.value
  );
const SEARCH_DEBOUNCE_MS = 300;
const notesQuery = ref(route.query.tab === 'notes' ? route.query.q || '' : '');
const notesSearch = computed(() => notesQuery.value.trim() || undefined);

const loadMoreNotes = () =>
  companiesStore.getCompanyNotes(
    companyId.value,
    (notesMeta.value.page || 1) + 1,
    notesSearch.value
  );

const searchNotes = useDebounceFn(() => {
  router.replace({ query: { tab: 'notes', q: notesSearch.value } });
  companiesStore.getCompanyNotes(companyId.value, 1, notesSearch.value);
}, SEARCH_DEBOUNCE_MS);

watch(notesQuery, searchNotes);

const peopleQuery = ref(
  route.query.tab === 'people' ? route.query.q || '' : ''
);
const setActiveTab = tab => {
  if (tab === activeTab.value) return;
  // Switching tabs drops the filters from the URL, so reload the unfiltered list.
  if (conversationFilters.value.length) {
    companiesStore.getCompanyConversations(companyId.value);
  }
  const search = { notes: notesSearch.value, people: peopleQuery.value.trim() };
  router.replace({ query: { tab, q: search[tab] || undefined } });
};

const goToCompaniesIndex = () => {
  router.push({
    name: 'companies_dashboard_index',
    params: { accountId: route.params.accountId },
    query: { page: '1' },
  });
};

const goToCompaniesList = () => {
  if (window.history.state?.back) {
    router.back();
    return;
  }
  goToCompaniesIndex();
};

const clearSelectedCandidate = () => {
  selectedCandidate.value = null;
};

const tabs = computed(() => [
  {
    value: 'conversations',
    icon: 'i-lucide-message-circle',
    label: t('COMPANIES.DETAIL.TABS.CONVERSATIONS'),
    count: conversationsMeta.value.allCount,
  },
  {
    value: 'notes',
    icon: 'i-lucide-notebook-pen',
    label: t('COMPANIES.DETAIL.TABS.NOTES'),
    count: notesMeta.value.totalCount,
  },
  {
    value: 'people',
    icon: 'i-lucide-contact',
    label: t('COMPANIES.DETAIL.TABS.PEOPLE'),
    count: company.value?.contactsCount,
  },
]);

const showOpenConversations = () => {
  conversationFilters.value = [
    {
      attributeKey: 'status',
      filterOperator: 'equal_to',
      values: [
        { id: 'open', name: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.open.TEXT') },
      ],
      queryOperator: 'and',
    },
  ];
  layoutRef.value?.scrollToTabs();
};

const handleContactSearch = async query => {
  await companiesStore.searchCompanyContactCandidates({
    companyId: companyId.value,
    search: query,
  });
};

const handleConfirmContactSelection = async () => {
  const candidate = selectedCandidate.value;
  if (!candidate) return;

  const isReassigning =
    candidate.company?.id && candidate.company.id !== companyId.value;
  const message = isReassigning
    ? t('COMPANIES.DETAIL.CONTACTS.MESSAGES.REASSIGN_SUCCESS')
    : t('COMPANIES.DETAIL.CONTACTS.MESSAGES.ADD_SUCCESS');

  try {
    await companiesStore.attachContactToCompany(companyId.value, candidate.id);
    const search = peopleQuery.value.trim();
    if (search) companiesStore.getCompanyContacts(companyId.value, 1, search);
    useAlert(message);
    clearSelectedCandidate();
  } catch {
    const errorMessage = isReassigning
      ? t('COMPANIES.DETAIL.CONTACTS.MESSAGES.REASSIGN_ERROR')
      : t('COMPANIES.DETAIL.CONTACTS.MESSAGES.ADD_ERROR');
    useAlert(errorMessage);
  }
};

const handleDeleteCompany = async () => {
  try {
    await companiesStore.delete(companyId.value);
    useAlert(t('COMPANIES.DETAIL.DELETE.MESSAGES.SUCCESS'));
    confirmDeleteDialogRef.value?.dialogRef.close();
    goToCompaniesIndex();
  } catch {
    useAlert(t('COMPANIES.DETAIL.DELETE.MESSAGES.ERROR'));
  }
};

watch(
  [companyId, isReady, showPaywall],
  async ([id, ready, paywalled]) => {
    companiesStore.resetCompanyDetailState();
    clearSelectedCandidate();
    if (!id || !ready || paywalled) return;
    await Promise.allSettled([
      companiesStore.show(id),
      companiesStore.getCompanyConversations(id, 1, conversationFilters.value),
      companiesStore.getCompanyNotes(id, 1, notesSearch.value),
    ]);
  },
  { immediate: true }
);

onBeforeUnmount(() => {
  companiesStore.resetCompanyDetailState();
});
</script>

<template>
  <DetailsPageLayout
    ref="layoutRef"
    :back-label="t('COMPANIES.HEADER')"
    :is-loading="showInitialLoadingState"
    :tabs="tabs"
    :active-tab="activeTab"
    @update:active-tab="setActiveTab"
    @back="goToCompaniesList"
  >
    <template v-if="showPaywall" #state>
      <Paywall feature-prefix="COMPANIES" />
    </template>
    <template v-else-if="!hasCompany" #state>
      <div class="flex flex-col gap-2 py-24">
        <span class="text-lg font-medium text-n-slate-12">
          {{ t('COMPANIES.DETAIL.EMPTY_STATE.TITLE') }}
        </span>
        <p class="max-w-md text-sm text-n-slate-11">
          {{ t('COMPANIES.DETAIL.EMPTY_STATE.SUBTITLE') }}
        </p>
      </div>
    </template>

    <template #header>
      <CompanyDetailHeader
        :company="company"
        :open-conversations-count="conversationsMeta.openCount"
        @edit="editDialogRef?.open()"
        @delete="confirmDeleteDialogRef?.dialogRef.open()"
        @show-open-conversations="showOpenConversations"
      />
      <CompanyFacts :company="company" />
    </template>

    <template #actions>
      <CompanyConversationFilters
        v-if="activeTab === 'conversations'"
        v-model="conversationFilters"
        class="ms-auto"
      />
      <CompanySearchInput
        v-else-if="activeTab === 'notes'"
        v-model="notesQuery"
        :placeholder="t('COMPANIES.DETAIL.ACTIVITY.SEARCH_NOTES')"
      />
      <template v-else>
        <CompanySearchInput
          v-model="peopleQuery"
          :placeholder="t('COMPANIES.DETAIL.PEOPLE.SEARCH')"
        />
        <Button
          :label="t('COMPANIES.DETAIL.PEOPLE.ADD')"
          icon="i-lucide-plus"
          color="slate"
          size="sm"
          class="shrink-0"
          @click="peopleDialogRef?.open()"
        />
      </template>
    </template>

    <CompanyConversationList
      v-if="activeTab === 'conversations'"
      :conversations="companyConversations"
      :filtered="conversationFilters.length > 0"
      :is-loading="uiFlags.fetchingConversations"
      :has-more="hasMoreConversations"
      @load-more="loadMoreConversations"
    />
    <CompanyNotesFeed
      v-else-if="activeTab === 'notes'"
      :notes="companyNotes"
      :is-loading="uiFlags.fetchingNotes"
      :has-more="hasMoreNotes"
      :empty-message="
        notesSearch
          ? t('COMPANIES.DETAIL.ACTIVITY.NO_MATCHING_NOTES')
          : t('COMPANIES.DETAIL.ACTIVITY.EMPTY_NOTES')
      "
      :highlight="notesSearch || ''"
      @load-more="loadMoreNotes"
    />
    <CompanyPeopleList v-else :company="company" :query="peopleQuery" />

    <CompanyEditPanel ref="editDialogRef" :company="company" />

    <Dialog
      ref="peopleDialogRef"
      :title="t('COMPANIES.DETAIL.PEOPLE.DIALOG_TITLE', { name: company.name })"
      :show-cancel-button="false"
      :show-confirm-button="false"
      width="xl"
    >
      <CompanyAddContact
        :company="company"
        :is-busy="uiFlags.creatingContact || uiFlags.removingContact"
        :search-results="contactSearchResults"
        :is-searching="uiFlags.searchingContacts"
        :selected-contact="selectedCandidate"
        @cancel-contact-selection="clearSelectedCandidate"
        @confirm-contact-selection="handleConfirmContactSelection"
        @search="handleContactSearch"
        @select-contact="contact => (selectedCandidate = contact)"
      />
    </Dialog>

    <ConfirmCompanyDeleteDialog
      ref="confirmDeleteDialogRef"
      :company="company"
      :is-loading="uiFlags.deletingItem"
      @confirm="handleDeleteCompany"
    />
  </DetailsPageLayout>
</template>
