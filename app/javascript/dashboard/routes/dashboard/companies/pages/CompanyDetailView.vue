<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useDebounceFn } from '@vueuse/core';
import { useAlert } from 'dashboard/composables';
import { useCompaniesPaywall } from 'dashboard/composables/useCompaniesPaywall';

import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Paywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import CompanyConversationFilters from 'dashboard/components-next/Companies/CompanyDetail/CompanyConversationFilters.vue';
import CompanyConversationList from 'dashboard/components-next/Companies/CompanyDetail/CompanyConversationList.vue';
import CompanyNotesFeed from 'dashboard/components-next/Companies/CompanyDetail/CompanyNotesFeed.vue';
import CompanyAddContact from 'dashboard/components-next/Companies/CompanyDetail/CompanyAddContact.vue';
import CompanyDetailHeader from 'dashboard/components-next/Companies/CompanyDetail/CompanyDetailHeader.vue';
import CompanyEditPanel from 'dashboard/components-next/Companies/CompanyDetail/CompanyEditPanel.vue';
import CompanyFacts from 'dashboard/components-next/Companies/CompanyDetail/CompanyFacts.vue';
import CompanySearchInput from 'dashboard/components-next/Companies/CompanyDetail/CompanySearchInput.vue';
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
const tabsRef = ref(null);
const TAB_VALUES = ['conversations', 'notes', 'people'];
const activeTab = computed(() =>
  TAB_VALUES.includes(route.query.tab) ? route.query.tab : TAB_VALUES[0]
);
const setActiveTab = tab => {
  if (tab === activeTab.value) return;
  router.replace({ query: { tab } });
};

const companyId = computed(() => Number(route.params.companyId));
// Cloud accounts without Companies (Hacker plan) see an upgrade prompt.
const { isReady, showPaywall } = useCompaniesPaywall();
const company = computed(() => companiesStore.getRecord(companyId.value));
const companyConversations = computed(
  () => companiesStore.companyConversations || []
);
const companyNotes = computed(() => companiesStore.companyNotes || []);
const conversationsMeta = computed(
  () => companiesStore.companyConversationsMeta
);
const notesMeta = computed(() => companiesStore.companyNotesMeta);
const contactSearchResults = computed(
  () => companiesStore.contactSearchResults
);
const uiFlags = computed(() => companiesStore.getUIFlags);

const isFetchingCompany = computed(() => uiFlags.value.fetchingItem);
const isFetchingContacts = computed(() => uiFlags.value.fetchingContacts);
const isFetchingConversations = computed(
  () => uiFlags.value.fetchingConversations
);
const isFetchingNotes = computed(() => uiFlags.value.fetchingNotes);
const isSearchingContacts = computed(() => uiFlags.value.searchingContacts);
const isManagingContacts = computed(
  () => uiFlags.value.creatingContact || uiFlags.value.removingContact
);
const isDeletingCompany = computed(() => uiFlags.value.deletingItem);
const hasCompany = computed(() => Boolean(company.value?.id));
const showInitialLoadingState = computed(
  () =>
    !isReady.value ||
    (!hasCompany.value && (isFetchingCompany.value || isFetchingContacts.value))
);

const openConversationsCount = computed(() =>
  Number(conversationsMeta.value.openCount || 0)
);
const hasMoreConversations = computed(
  () =>
    companyConversations.value.length <
    Number(conversationsMeta.value.totalCount || 0)
);
const hasMoreNotes = computed(
  () => companyNotes.value.length < Number(notesMeta.value.totalCount || 0)
);

// ConversationFilter conditions live in the URL so returning from a conversation restores them.
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
    Number(conversationsMeta.value.page || 1) + 1,
    conversationFilters.value
  );
const SEARCH_DEBOUNCE_MS = 300;
const notesQuery = ref(route.query.tab === 'notes' ? route.query.q || '' : '');
const notesSearch = computed(() => notesQuery.value.trim() || undefined);

const loadMoreNotes = () =>
  companiesStore.getCompanyNotes(
    companyId.value,
    Number(notesMeta.value.page || 1) + 1,
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

const openEditCompanyDialog = () => {
  editDialogRef.value?.open();
};

const openDeleteCompanyDialog = () => {
  confirmDeleteDialogRef.value?.dialogRef.open();
};

const clearSelectedCandidate = () => {
  selectedCandidate.value = null;
};

const tabs = computed(() => [
  {
    value: 'conversations',
    icon: 'i-lucide-message-circle',
    label: t('COMPANIES.DETAIL.TABS.CONVERSATIONS'),
    count: Number(conversationsMeta.value.allCount || 0),
  },
  {
    value: 'notes',
    icon: 'i-lucide-notebook-pen',
    label: t('COMPANIES.DETAIL.TABS.NOTES'),
    count: Number(notesMeta.value.totalCount || 0),
  },
  {
    value: 'people',
    icon: 'i-lucide-contact',
    label: t('COMPANIES.DETAIL.TABS.PEOPLE'),
    count: company.value?.contactsCount || 0,
  },
]);

const activeTabIndex = computed(() =>
  tabs.value.findIndex(tab => tab.value === activeTab.value)
);

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
  tabsRef.value?.scrollIntoView({ behavior: 'smooth', block: 'start' });
};

const openPeopleDialog = () => {
  peopleDialogRef.value?.open();
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
  <section class="w-full h-full overflow-y-auto bg-n-surface-1">
    <div class="flex flex-col w-full max-w-5xl gap-8 px-6 pt-6 pb-24 mx-auto">
      <Button
        :label="t('COMPANIES.HEADER')"
        icon="i-lucide-arrow-left"
        variant="link"
        color="slate"
        size="sm"
        class="self-start -mb-4"
        @click="goToCompaniesList"
      />

      <Paywall v-if="showPaywall" feature-prefix="COMPANIES" />

      <div
        v-else-if="showInitialLoadingState"
        class="flex justify-center py-24 text-n-slate-11"
      >
        <Spinner />
      </div>

      <div v-else-if="!hasCompany" class="flex flex-col gap-2 py-24">
        <span class="text-lg font-medium text-n-slate-12">
          {{ t('COMPANIES.DETAIL.EMPTY_STATE.TITLE') }}
        </span>
        <p class="max-w-md text-sm text-n-slate-11">
          {{ t('COMPANIES.DETAIL.EMPTY_STATE.SUBTITLE') }}
        </p>
      </div>

      <template v-else>
        <section
          class="overflow-hidden border rounded-xl border-n-weak bg-n-solid-1"
        >
          <div class="flex flex-col gap-5 p-6">
            <CompanyDetailHeader
              :company="company"
              :open-conversations-count="openConversationsCount"
              @edit="openEditCompanyDialog"
              @delete="openDeleteCompanyDialog"
              @show-open-conversations="showOpenConversations"
            />
            <CompanyFacts :company="company" />
          </div>
        </section>

        <div class="flex flex-col gap-4">
          <div
            ref="tabsRef"
            class="sticky top-0 z-10 flex flex-wrap items-center justify-between gap-3 py-3 border-b bg-n-surface-1 border-n-weak"
          >
            <TabBar
              :tabs="tabs"
              :initial-active-tab="activeTabIndex"
              @tab-changed="tab => setActiveTab(tab.value)"
            />
            <div class="flex items-center w-full gap-2 sm:w-auto">
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
                  @click="openPeopleDialog"
                />
              </template>
            </div>
          </div>

          <CompanyConversationList
            v-if="activeTab === 'conversations'"
            :conversations="companyConversations"
            :filtered="conversationFilters.length > 0"
            :is-loading="isFetchingConversations"
            :has-more="hasMoreConversations"
            @load-more="loadMoreConversations"
          />
          <CompanyNotesFeed
            v-else-if="activeTab === 'notes'"
            :notes="companyNotes"
            :is-loading="isFetchingNotes"
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
        </div>

        <CompanyEditPanel ref="editDialogRef" :company="company" />

        <Dialog
          ref="peopleDialogRef"
          :title="
            t('COMPANIES.DETAIL.PEOPLE.DIALOG_TITLE', { name: company.name })
          "
          :show-cancel-button="false"
          :show-confirm-button="false"
          width="xl"
        >
          <CompanyAddContact
            :company="company"
            :is-busy="isManagingContacts"
            :search-results="contactSearchResults"
            :is-searching="isSearchingContacts"
            :selected-contact="selectedCandidate"
            @cancel-contact-selection="clearSelectedCandidate"
            @confirm-contact-selection="handleConfirmContactSelection"
            @search="handleContactSearch"
            @select-contact="contact => (selectedCandidate = contact)"
          />
        </Dialog>
      </template>
    </div>

    <ConfirmCompanyDeleteDialog
      ref="confirmDeleteDialogRef"
      :company="company"
      :is-loading="isDeletingCompany"
      @confirm="handleDeleteCompany"
    />
  </section>
</template>
