<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';

import Policy from 'dashboard/components/policy.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CompaniesDetailsLayout from 'dashboard/components-next/Companies/CompaniesDetailsLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import CompanyContactsSidebar from 'dashboard/components-next/Companies/CompanyDetail/CompanyContactsSidebar.vue';
import CompanyCustomAttributes from 'dashboard/components-next/Companies/CompanyDetail/CompanyCustomAttributes.vue';
import CompanyProfileCard from 'dashboard/components-next/Companies/CompanyDetail/CompanyProfileCard.vue';
import ConfirmCompanyDeleteDialog from 'dashboard/components-next/Companies/CompanyDetail/ConfirmCompanyDeleteDialog.vue';
import { useCompaniesStore } from 'dashboard/stores/companies';

const route = useRoute();
const router = useRouter();
const companiesStore = useCompaniesStore();
const { t } = useI18n();

const confirmDeleteDialogRef = ref(null);
const selectedCandidate = ref(null);
const activeSidebarTab = ref('attributes');

const companyId = computed(() => Number(route.params.companyId));
const company = computed(() => companiesStore.getRecord(companyId.value));
const companyContacts = computed(() => companiesStore.companyContacts);
const companyContactsMeta = computed(() => companiesStore.companyContactsMeta);
const contactSearchResults = computed(
  () => companiesStore.contactSearchResults
);
const uiFlags = computed(() => companiesStore.getUIFlags);

const isFetchingCompany = computed(() => uiFlags.value.fetchingItem);
const isFetchingContacts = computed(() => uiFlags.value.fetchingContacts);
const isSearchingContacts = computed(() => uiFlags.value.searchingContacts);
const isManagingContacts = computed(
  () => uiFlags.value.creatingContact || uiFlags.value.removingContact
);
const isDeletingCompany = computed(() => uiFlags.value.deletingItem);
const hasCompany = computed(() => Boolean(company.value?.id));
const showInitialLoadingState = computed(
  () =>
    !hasCompany.value && (isFetchingCompany.value || isFetchingContacts.value)
);

const breadcrumbItems = computed(() => [
  { label: t('COMPANIES.HEADER') },
  ...(hasCompany.value
    ? [{ label: company.value?.name || t('COMPANIES.UNNAMED') }]
    : []),
]);

const sidebarTabs = computed(() => [
  { label: t('COMPANIES.DETAIL.SIDEBAR.TABS.ATTRIBUTES'), value: 'attributes' },
  {
    label: t('COMPANIES.DETAIL.SIDEBAR.TABS.CONTACTS'),
    value: 'contacts',
    count: Number(company.value?.contactsCount || 0),
  },
]);

const activeSidebarTabIndex = computed(() =>
  sidebarTabs.value.findIndex(tab => tab.value === activeSidebarTab.value)
);

const goToCompaniesIndex = () => {
  router.push({
    name: 'companies_dashboard_index',
    params: { accountId: route.params.accountId },
    query: { page: '1' },
  });
};

const goToCompaniesList = () => {
  if (window.history.state?.back || window.history.length > 1) {
    router.back();
    return;
  }
  goToCompaniesIndex();
};

const loadCompanyContactsPage = async page => {
  if (!companyId.value) return;
  await companiesStore.getCompanyContacts(companyId.value, page);
};

const openDeleteCompanyDialog = () => {
  confirmDeleteDialogRef.value?.dialogRef.open();
};

const clearSelectedCandidate = () => {
  selectedCandidate.value = null;
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

  try {
    await companiesStore.attachContactToCompany(companyId.value, candidate.id);
    useAlert(
      t(
        isReassigning
          ? 'COMPANIES.DETAIL.CONTACTS.MESSAGES.REASSIGN_SUCCESS'
          : 'COMPANIES.DETAIL.CONTACTS.MESSAGES.ADD_SUCCESS'
      )
    );
    clearSelectedCandidate();
  } catch {
    useAlert(
      t(
        isReassigning
          ? 'COMPANIES.DETAIL.CONTACTS.MESSAGES.REASSIGN_ERROR'
          : 'COMPANIES.DETAIL.CONTACTS.MESSAGES.ADD_ERROR'
      )
    );
  }
};

const handleRemoveContact = async contactId => {
  const currentPage = Number(companyContactsMeta.value.page || 1);
  const nextPage =
    currentPage > 1 && companyContacts.value.length === 1
      ? currentPage - 1
      : currentPage;

  try {
    await companiesStore.removeContactFromCompany(
      companyId.value,
      contactId,
      nextPage
    );
    useAlert(t('COMPANIES.DETAIL.CONTACTS.MESSAGES.REMOVE_SUCCESS'));
  } catch {
    useAlert(t('COMPANIES.DETAIL.CONTACTS.MESSAGES.REMOVE_ERROR'));
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
  companyId,
  async id => {
    companiesStore.resetCompanyDetailState();
    clearSelectedCandidate();
    if (!id) return;
    await Promise.allSettled([
      companiesStore.show(id),
      companiesStore.getCompanyContacts(id),
    ]);
  },
  { immediate: true }
);

onBeforeUnmount(() => {
  companiesStore.resetCompanyDetailState();
});
</script>

<template>
  <CompaniesDetailsLayout
    :breadcrumb-items="breadcrumbItems"
    @back="goToCompaniesList"
  >
    <div
      v-if="showInitialLoadingState"
      class="flex flex-col items-center justify-center gap-3 py-24 text-n-slate-11"
    >
      <Spinner />
      <span class="text-sm">{{ t('COMPANIES.DETAIL.LOADING') }}</span>
    </div>

    <div
      v-else-if="!hasCompany"
      class="flex flex-col items-center justify-center gap-3 px-6 py-24 text-center rounded-2xl border border-n-weak bg-n-solid-2"
    >
      <span class="text-lg font-medium text-n-slate-12">
        {{ t('COMPANIES.DETAIL.EMPTY_STATE.TITLE') }}
      </span>
      <p class="max-w-md text-sm text-n-slate-11">
        {{ t('COMPANIES.DETAIL.EMPTY_STATE.SUBTITLE') }}
      </p>
    </div>

    <div v-else class="flex flex-col gap-6">
      <CompanyProfileCard :company="company" :is-loading="isFetchingCompany" />

      <Policy :permissions="['administrator']">
        <section
          class="flex flex-col items-start w-full gap-4 pt-6 border-t border-n-strong"
        >
          <div class="flex flex-col gap-2">
            <h6 class="text-base font-medium text-n-slate-12">
              {{ t('COMPANIES.DETAIL.DELETE.SECTION_TITLE') }}
            </h6>
            <span class="text-sm text-n-slate-11">
              {{ t('COMPANIES.DETAIL.DELETE.SECTION_DESCRIPTION') }}
            </span>
          </div>
          <Button
            :label="t('COMPANIES.DETAIL.DELETE.BUTTON')"
            color="ruby"
            :disabled="isDeletingCompany"
            @click="openDeleteCompanyDialog"
          />
        </section>
      </Policy>
    </div>

    <template v-if="hasCompany" #sidebar>
      <div class="flex flex-col">
        <div class="px-6">
          <TabBar
            :tabs="sidebarTabs"
            :initial-active-tab="activeSidebarTabIndex"
            class="w-full [&>button]:w-full bg-n-alpha-black2"
            @tab-changed="tab => (activeSidebarTab = tab.value)"
          />
        </div>

        <CompanyCustomAttributes
          v-if="activeSidebarTab === 'attributes'"
          :company="company"
        />

        <CompanyContactsSidebar
          v-else-if="activeSidebarTab === 'contacts'"
          :company="company"
          :contacts="companyContacts"
          :meta="companyContactsMeta"
          :is-loading="isFetchingContacts"
          :is-busy="isManagingContacts"
          :search-results="contactSearchResults"
          :is-searching="isSearchingContacts"
          :selected-contact="selectedCandidate"
          @cancel-contact-selection="clearSelectedCandidate"
          @confirm-contact-selection="handleConfirmContactSelection"
          @search="handleContactSearch"
          @select-contact="contact => (selectedCandidate = contact)"
          @remove-contact="handleRemoveContact"
          @update:current-page="loadCompanyContactsPage"
        />
      </div>
    </template>

    <ConfirmCompanyDeleteDialog
      ref="confirmDeleteDialogRef"
      :company="company"
      :is-loading="isDeletingCompany"
      @confirm="handleDeleteCompany"
    />
  </CompaniesDetailsLayout>
</template>
