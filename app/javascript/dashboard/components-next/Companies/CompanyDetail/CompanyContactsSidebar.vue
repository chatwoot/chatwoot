<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { debounce } from '@chatwoot/utils';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';

const props = defineProps({
  company: {
    type: Object,
    default: () => ({}),
  },
  contacts: {
    type: Array,
    default: () => [],
  },
  meta: {
    type: Object,
    default: () => ({}),
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  isBusy: {
    type: Boolean,
    default: false,
  },
  searchResults: {
    type: Array,
    default: () => [],
  },
  isSearching: {
    type: Boolean,
    default: false,
  },
  selectedContact: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits([
  'cancelContactSelection',
  'confirmContactSelection',
  'removeContact',
  'search',
  'selectContact',
  'update:currentPage',
]);

const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const selectedContactId = ref(null);
const searchQuery = ref('');

const hasContacts = computed(() => props.contacts.length > 0);
const currentPage = computed(() => Number(props.meta?.page || 1));
const totalContacts = computed(() => Number(props.meta?.totalCount || 0));
const linkedContactIds = computed(
  () => new Set(props.contacts.map(contact => Number(contact.id)))
);
const showPaginationFooter = computed(
  () => hasContacts.value && totalContacts.value > props.contacts.length
);

const openContact = contactId => {
  router.push({
    name: 'contacts_edit',
    params: {
      accountId: route.params.accountId,
      contactId,
    },
  });
};

const contactMeta = contact =>
  [contact.email, contact.phoneNumber].filter(Boolean).join(' • ');

const contactName = contact =>
  contact.name || t('COMPANIES.DETAIL.CONTACTS.UNNAMED_CONTACT');

const contactOptions = computed(() =>
  props.searchResults
    .filter(
      contact =>
        !contact.linkedToCurrentCompany &&
        !linkedContactIds.value.has(Number(contact.id))
    )
    .map(contact => ({
      value: contact.id,
      label: [contactName(contact), contact.email, contact.phoneNumber]
        .filter(Boolean)
        .join(' · '),
    }))
);

const emptyState = computed(() => {
  if (props.isSearching) {
    return t('COMPANIES.DETAIL.CONTACTS.LOADING');
  }

  return searchQuery.value.trim()
    ? t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.EMPTY')
    : t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.INITIAL');
});

const selectedContactName = computed(() =>
  props.selectedContact ? contactName(props.selectedContact) : ''
);

const selectedContactMeta = computed(() =>
  props.selectedContact ? contactMeta(props.selectedContact) : ''
);

const selectedContactCompanyName = computed(
  () => props.selectedContact?.company?.name || ''
);

const debouncedSearch = debounce(query => {
  emit('search', query);
}, 300);

const handleSearch = query => {
  searchQuery.value = query;
  debouncedSearch(query.trim());
};

const handleContactSelect = contactId => {
  const selectedContact = props.searchResults.find(
    contact => contact.id === Number(contactId)
  );

  selectedContactId.value = null;
  if (selectedContact) {
    emit('selectContact', selectedContact);
  }
};
</script>

<template>
  <div class="flex flex-col gap-6 px-6 py-6">
    <div v-if="!selectedContact" class="flex flex-col gap-3">
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('COMPANIES.DETAIL.CONTACTS.ACTIONS.ADD') }}
        </label>
        <span class="text-sm leading-5 text-n-slate-11">
          {{ t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.DESCRIPTION') }}
        </span>
      </div>
      <ComboBox
        use-api-results
        :model-value="selectedContactId"
        :options="contactOptions"
        :disabled="isBusy"
        :empty-state="emptyState"
        :search-placeholder="
          t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.SEARCH_PLACEHOLDER')
        "
        :placeholder="t('COMPANIES.DETAIL.CONTACTS.ACTIONS.ADD')"
        class="[&>div>button]:bg-n-alpha-black2"
        @search="handleSearch"
        @update:model-value="handleContactSelect"
      />
    </div>

    <div v-else class="flex flex-col gap-4">
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.CONFIRM_TITLE') }}
        </label>
        <span class="text-sm leading-5 text-n-slate-11">
          {{ t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.CONFIRM_DESCRIPTION') }}
        </span>
      </div>

      <div class="flex flex-col">
        <div class="flex items-center justify-between h-5 gap-2">
          <label class="text-sm text-n-slate-12">
            {{ t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.COMPANY_LABEL') }}
          </label>
        </div>

        <div
          class="flex items-center gap-3 p-3 border rounded-xl border-n-strong"
        >
          <Avatar
            :name="company.name || t('COMPANIES.UNNAMED')"
            :src="company.avatarUrl"
            :size="32"
            rounded-full
            hide-offline-status
          />
          <div class="flex flex-col min-w-0 gap-1">
            <span class="text-sm leading-4 truncate text-n-slate-12">
              {{ company.name || t('COMPANIES.UNNAMED') }}
            </span>
            <span
              v-if="company.domain"
              class="text-sm leading-4 truncate text-n-slate-11"
            >
              {{ company.domain }}
            </span>
          </div>
        </div>

        <div class="flex items-center justify-between h-5 gap-2">
          <label class="text-sm text-n-slate-12">
            {{ t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.CONTACT_LABEL') }}
          </label>
          <span
            v-if="selectedContactCompanyName"
            class="px-2 py-0.5 text-xs rounded-md text-n-amber-11 bg-n-alpha-2"
          >
            {{
              t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.CURRENT_COMPANY', {
                companyName: selectedContactCompanyName,
              })
            }}
          </span>
        </div>

        <div
          class="flex items-center gap-3 p-3 border rounded-xl border-n-strong"
        >
          <Avatar
            :name="selectedContactName"
            :src="selectedContact.thumbnail"
            :size="32"
            rounded-full
            hide-offline-status
          />
          <div class="flex flex-col min-w-0 gap-1">
            <span class="text-sm leading-4 truncate text-n-slate-12">
              {{ selectedContactName }}
            </span>
            <span
              v-if="selectedContactMeta"
              class="text-sm leading-4 truncate text-n-slate-11"
            >
              {{ selectedContactMeta }}
            </span>
          </div>
        </div>
      </div>

      <div class="flex items-center justify-between gap-3">
        <Button
          variant="faded"
          color="slate"
          :label="t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.CANCEL')"
          class="w-full bg-n-alpha-2 text-n-blue-11 hover:bg-n-alpha-3"
          :disabled="isBusy"
          @click="emit('cancelContactSelection')"
        />
        <Button
          :label="t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.ADD')"
          class="w-full"
          :is-loading="isBusy"
          :disabled="isBusy"
          @click="emit('confirmContactSelection')"
        />
      </div>
    </div>

    <div class="flex flex-col gap-3">
      <div class="flex items-center justify-between gap-3">
        <h4 class="text-sm font-medium text-n-slate-12">
          {{ t('COMPANIES.DETAIL.SIDEBAR.TABS.CONTACTS') }}
        </h4>
        <span v-if="hasContacts" class="text-xs tabular-nums text-n-slate-11">
          {{ t('COMPANIES.CONTACTS_COUNT', { n: totalContacts }) }}
        </span>
      </div>

      <div
        v-if="isLoading && !hasContacts"
        class="py-8 text-sm text-center rounded-xl border border-dashed border-n-weak text-n-slate-11"
      >
        {{ t('COMPANIES.DETAIL.CONTACTS.LOADING') }}
      </div>

      <div
        v-else-if="!hasContacts"
        class="py-8 text-sm text-center rounded-xl border border-dashed border-n-weak text-n-slate-11"
      >
        {{ t('COMPANIES.DETAIL.CONTACTS.EMPTY') }}
      </div>

      <div v-else class="flex flex-col border-y border-n-weak">
        <div
          v-for="contact in contacts"
          :key="contact.id"
          class="flex items-center gap-2 py-3 border-b group/contact border-n-weak last:border-b-0"
        >
          <button
            type="button"
            class="flex items-center flex-1 min-w-0 gap-3 text-left rounded-lg transition-colors text-n-slate-12 hover:text-n-blue-11 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-n-brand focus-visible:ring-offset-2 focus-visible:ring-offset-n-background"
            @click="openContact(contact.id)"
          >
            <Avatar
              :name="contactName(contact)"
              :src="contact.thumbnail"
              :size="32"
              rounded-full
              hide-offline-status
            />
            <div class="min-w-0">
              <p class="text-sm font-medium leading-5 truncate text-n-slate-12">
                {{ contactName(contact) }}
              </p>
              <p
                v-if="contactMeta(contact)"
                class="text-sm leading-5 truncate text-n-slate-11"
              >
                {{ contactMeta(contact) }}
              </p>
            </div>
          </button>

          <Button
            icon="i-lucide-unlink"
            color="slate"
            variant="ghost"
            size="xs"
            class="shrink-0 opacity-70 transition-opacity sm:opacity-0 sm:group-hover/contact:opacity-100 sm:focus-visible:opacity-100"
            :disabled="isBusy"
            :title="t('COMPANIES.DETAIL.CONTACTS.ACTIONS.REMOVE')"
            :aria-label="t('COMPANIES.DETAIL.CONTACTS.ACTIONS.REMOVE')"
            @click.stop="emit('removeContact', contact.id)"
          />
        </div>
      </div>

      <PaginationFooter
        v-if="showPaginationFooter"
        current-page-info="CONTACTS_LAYOUT.PAGINATION_FOOTER.SHOWING"
        :current-page="currentPage"
        :total-items="totalContacts"
        :items-per-page="15"
        class="px-0 before:hidden"
        @update:current-page="emit('update:currentPage', $event)"
      />
    </div>
  </div>
</template>
