<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  company: {
    type: Object,
    default: () => ({}),
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
  'search',
  'selectContact',
]);

const { t } = useI18n();

const selectedContactId = ref(null);
const searchQuery = ref('');

const contactMeta = contact =>
  [contact.email, contact.phoneNumber].filter(Boolean).join(' • ');

const contactName = contact =>
  contact.name || t('COMPANIES.DETAIL.CONTACTS.UNNAMED_CONTACT');

const contactOptions = computed(() =>
  props.searchResults
    .filter(contact => !contact.linkedToCurrentCompany)
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

const summaryRows = computed(() => [
  {
    key: 'company',
    label: t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.COMPANY_LABEL'),
    avatarName: props.company.name || t('COMPANIES.UNNAMED'),
    avatarSrc: props.company.avatarUrl,
    primary: props.company.name || t('COMPANIES.UNNAMED'),
    secondary: props.company.domain,
  },
  {
    key: 'contact',
    label: t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.CONTACT_LABEL'),
    badge: selectedContactCompanyName.value
      ? t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.CURRENT_COMPANY', {
          companyName: selectedContactCompanyName.value,
        })
      : '',
    avatarName: selectedContactName.value,
    avatarSrc: props.selectedContact?.thumbnail,
    primary: selectedContactName.value,
    secondary: selectedContactMeta.value,
  },
]);

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
  <div class="flex flex-col gap-6">
    <div v-if="!selectedContact" class="flex flex-col gap-4">
      <span class="text-body-main text-n-slate-11">
        {{ t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.DESCRIPTION') }}
      </span>
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
      <div class="flex flex-col gap-2">
        <label class="text-base text-n-slate-12">
          {{ t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.CONFIRM_TITLE') }}
        </label>
        <span class="text-sm text-n-slate-11">
          {{ t('COMPANIES.DETAIL.CONTACTS.DIALOGS.ADD.CONFIRM_DESCRIPTION') }}
        </span>
      </div>

      <div class="flex flex-col gap-4">
        <div
          v-for="row in summaryRows"
          :key="row.key"
          class="flex flex-col gap-2"
        >
          <div class="flex items-center justify-between h-5 gap-2">
            <label class="text-sm text-n-slate-12">
              {{ row.label }}
            </label>
            <span
              v-if="row.badge"
              class="px-2 py-0.5 text-xs rounded-md text-n-amber-11 bg-n-alpha-2"
            >
              {{ row.badge }}
            </span>
          </div>

          <div
            class="border border-n-strong h-[60px] gap-2 flex items-center rounded-xl p-3"
          >
            <Avatar
              :name="row.avatarName"
              :src="row.avatarSrc"
              :size="32"
              hide-offline-status
            />
            <div class="flex flex-col w-full min-w-0 gap-1">
              <span
                class="text-sm leading-4 font-medium truncate text-n-slate-12"
              >
                {{ row.primary }}
              </span>
              <span
                v-if="row.secondary"
                class="text-sm leading-4 truncate text-n-slate-11"
              >
                {{ row.secondary }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <div class="flex items-center justify-between gap-3 mt-2">
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
  </div>
</template>
