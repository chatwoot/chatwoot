<script setup>
import { computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useDebounceFn } from '@vueuse/core';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Flag from 'dashboard/components-next/flag/Flag.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { useCompaniesStore } from 'dashboard/stores/companies';

const props = defineProps({
  company: { type: Object, required: true },
  // Search term from the page toolbar.
  query: { type: String, default: '' },
});

const SEARCH_DEBOUNCE_MS = 300;
// Matches Api::V1::Accounts::Companies::ContactsController::RESULTS_PER_PAGE
const PAGE_SIZE = 25;

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { accountId } = useAccount();
const companiesStore = useCompaniesStore();

const contacts = computed(() => companiesStore.companyContacts);
const meta = computed(() => companiesStore.companyContactsMeta);
const isLoading = computed(() => companiesStore.getUIFlags.fetchingContacts);
const isRemoving = computed(() => companiesStore.getUIFlags.removingContact);

const page = computed(() => Number(meta.value.page || 1));
const matchCount = computed(() => Number(meta.value.totalCount || 0));

// Keep page and search in the URL so returning from a contact restores the list.
const fetchPage = targetPage => {
  const search = props.query.trim() || undefined;
  router.replace({
    query: {
      ...route.query,
      page: targetPage > 1 ? String(targetPage) : undefined,
      q: search,
    },
  });
  return companiesStore.getCompanyContacts(
    props.company.id,
    targetPage,
    search
  );
};

onMounted(() => fetchPage(Number(route.query.page) || 1));

const debouncedSearch = useDebounceFn(() => fetchPage(1), SEARCH_DEBOUNCE_MS);
watch(() => props.query, debouncedSearch);

const contactName = contact =>
  contact.name ||
  contact.email ||
  t('COMPANIES.DETAIL.CONTACTS.UNNAMED_CONTACT');

const contactMeta = contact => {
  const { city, country, countryCode } = contact.additionalAttributes || {};
  const location = [city, country].filter(Boolean).join(', ');
  return [
    contact.email && { key: 'email', label: contact.email },
    contact.phoneNumber && { key: 'phone', label: contact.phoneNumber },
    location && { key: 'location', label: location, countryCode },
  ].filter(Boolean);
};

const openContact = contactId => {
  router.push({
    name: 'contacts_edit',
    params: { accountId: accountId.value, contactId },
  });
};

const removeContact = async contact => {
  const targetPage =
    page.value > 1 && contacts.value.length === 1 ? page.value - 1 : page.value;
  try {
    await companiesStore.removeContactFromCompany(
      props.company.id,
      contact.id,
      targetPage
    );
    if (props.query.trim()) await fetchPage(targetPage);
    useAlert(t('COMPANIES.DETAIL.CONTACTS.MESSAGES.REMOVE_SUCCESS'));
  } catch {
    useAlert(t('COMPANIES.DETAIL.CONTACTS.MESSAGES.REMOVE_ERROR'));
  }
};
</script>

<template>
  <section class="flex flex-col gap-4">
    <div
      v-if="isLoading && !contacts.length"
      class="flex justify-center py-12 text-n-slate-11"
    >
      <Spinner />
    </div>

    <div v-else-if="contacts.length" class="divide-y divide-n-weak">
      <div
        v-for="contact in contacts"
        :key="contact.id"
        class="flex items-start justify-between gap-4 py-4"
      >
        <div class="flex items-start flex-1 min-w-0 gap-4">
          <Avatar
            :name="contactName(contact)"
            :src="contact.thumbnail"
            :size="40"
            hide-offline-status
          />
          <div class="flex flex-col flex-1 min-w-0 gap-1">
            <button
              type="button"
              class="block p-0 truncate text-heading-3 text-start text-n-slate-12 hover:text-n-blue-11"
              @click="openContact(contact.id)"
            >
              {{ contactName(contact) }}
            </button>
            <div
              v-if="contactMeta(contact).length"
              class="flex flex-wrap items-center gap-x-3 gap-y-1"
            >
              <template
                v-for="(item, index) in contactMeta(contact)"
                :key="item.key"
              >
                <div v-if="index" class="w-px h-3 bg-n-slate-6" />
                <span
                  class="inline-flex items-center gap-1.5 truncate text-n-slate-11 text-body-main max-w-72"
                  :title="item.label"
                >
                  <Flag
                    v-if="item.countryCode"
                    :country="item.countryCode"
                    class="size-3.5"
                  />
                  {{ item.label }}
                </span>
              </template>
            </div>
          </div>
        </div>
        <Button
          v-tooltip.top="t('COMPANIES.DETAIL.CONTACTS.ACTIONS.REMOVE')"
          icon="i-lucide-unlink"
          slate
          sm
          class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
          :disabled="isRemoving"
          @click="removeContact(contact)"
        />
      </div>
    </div>

    <p
      v-else
      class="px-4 py-10 text-sm text-center border border-dashed rounded-xl border-n-weak text-n-slate-11"
    >
      {{
        query.trim()
          ? t('COMPANIES.DETAIL.PEOPLE.NO_MATCHES')
          : t('COMPANIES.DETAIL.PEOPLE.EMPTY')
      }}
    </p>

    <PaginationFooter
      v-if="matchCount > PAGE_SIZE"
      current-page-info="CONTACTS_LAYOUT.PAGINATION_FOOTER.SHOWING"
      :current-page="page"
      :total-items="matchCount"
      :items-per-page="PAGE_SIZE"
      class="!px-0 before:hidden bg-transparent"
      @update:current-page="fetchPage"
    />
  </section>
</template>
