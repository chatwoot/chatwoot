<script setup>
import { computed } from 'vue';

import { useI18n } from 'vue-i18n';

import { dynamicTime } from 'shared/helpers/timeHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

const props = defineProps({
  contacts: { type: Array, required: true },

  selectedContactIds: { type: Array, default: () => [] },

  activeSort: { type: String, default: 'last_activity_at' },

  activeOrdering: { type: String, default: '' },
});

const emit = defineEmits(['toggleContact', 'showContact', 'update:sort']);

const { t } = useI18n();

const selectedIdsSet = computed(() => new Set(props.selectedContactIds || []));

const allSelected = computed(
  () =>
    props.contacts.length > 0 &&
    props.contacts.every(contact => selectedIdsSet.value.has(contact.id))
);

const SORTABLE_COLUMNS = [
  {
    key: 'name',

    label: t('CONTACTS_LAYOUT.HEADER.ACTIONS.SORT_BY.OPTIONS.NAME'),
  },

  {
    key: 'email',

    label: t('CONTACTS_LAYOUT.HEADER.ACTIONS.SORT_BY.OPTIONS.EMAIL'),
  },

  {
    key: 'document_number',

    label: t('CONTACTS_LAYOUT.HEADER.ACTIONS.SORT_BY.OPTIONS.DOCUMENT_NUMBER'),
  },

  {
    key: 'phone_number',

    label: t('CONTACTS_LAYOUT.HEADER.ACTIONS.SORT_BY.OPTIONS.PHONE_NUMBER'),
  },

  {
    key: 'last_activity_at',

    label: t('CONTACTS_LAYOUT.HEADER.ACTIONS.SORT_BY.OPTIONS.LAST_ACTIVITY'),
  },
];

const isSortedBy = key => props.activeSort === key;

const sortIcon = key => {
  if (!isSortedBy(key)) return 'i-lucide-arrow-up-down';

  return props.activeOrdering === '-'
    ? 'i-lucide-arrow-down'
    : 'i-lucide-arrow-up';
};

const handleHeaderClick = key => {
  const isSame = props.activeSort === key;

  let order = '';

  if (isSame) {
    order = props.activeOrdering === '-' ? '' : '-';
  }

  emit('update:sort', { sort: key, order });
};

const toggleSelectAll = () => {
  const shouldSelect = !allSelected.value;

  props.contacts.forEach(contact => {
    emit('toggleContact', { id: contact.id, value: shouldSelect });
  });
};

const toggleContact = (id, value) => {
  emit('toggleContact', { id, value });
};

const onClickViewDetails = id => {
  emit('showContact', id);
};

const onRowKeydown = (event, id) => {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault();

    onClickViewDetails(id);
  }
};

const formatLastActivity = timestamp => {
  if (!timestamp) return '—';

  return dynamicTime(timestamp);
};

const companyName = contact => contact.additionalAttributes?.companyName || '';
</script>

<template>
  <div class="hidden md:block w-full overflow-x-auto">
    <table class="w-full table-auto divide-y divide-n-weak">
      <thead class="border-t border-n-weak bg-n-surface-2">
        <tr>
          <th class="py-3 px-4 w-10">
            <Checkbox
              :model-value="allSelected"
              @change="event => toggleSelectAll(event.target.checked)"
            />
          </th>

          <th
            v-for="column in SORTABLE_COLUMNS"
            :key="column.key"
            class="py-3 px-4 text-start text-xs font-semibold text-n-slate-11 uppercase tracking-wider cursor-pointer select-none hover:text-n-slate-12"
            @click="handleHeaderClick(column.key)"
          >
            <span class="inline-flex items-center gap-1">
              {{ column.label }}

              <span
                class="size-3.5"
                :class="[
                  sortIcon(column.key),

                  isSortedBy(column.key) ? 'text-n-slate-12' : 'text-n-slate-9',
                ]"
              />
            </span>
          </th>
        </tr>
      </thead>

      <tbody class="divide-y divide-n-weak">
        <tr
          v-for="contact in contacts"
          :key="contact.id"
          role="button"
          tabindex="0"
          class="group cursor-pointer hover:bg-n-alpha-2 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-n-brand"
          :class="{
            'bg-n-slate-3 dark:bg-n-solid-3': selectedIdsSet.has(contact.id),
          }"
          @click="onClickViewDetails(contact.id)"
          @keydown="onRowKeydown($event, contact.id)"
        >
          <td class="py-3 px-4" @click.stop>
            <Checkbox
              :model-value="selectedIdsSet.has(contact.id)"
              @change="event => toggleContact(contact.id, event.target.checked)"
            />
          </td>

          <td class="py-3 px-4">
            <div class="flex items-center gap-3">
              <Avatar
                :name="contact.name"
                :src="contact.thumbnail"
                :size="36"
                hide-offline-status
              />

              <div class="flex flex-col min-w-0">
                <span class="text-sm font-medium text-n-slate-12 truncate">
                  {{ contact.name || '—' }}
                </span>

                <span
                  v-if="companyName(contact)"
                  class="text-xs text-n-slate-10 truncate"
                >
                  {{ companyName(contact) }}
                </span>
              </div>
            </div>
          </td>

          <td class="py-3 px-4">
            <span class="text-sm text-n-slate-11 truncate">{{
              contact.email || '—'
            }}</span>
          </td>

          <td class="py-3 px-4">
            <span class="text-sm text-n-slate-11 truncate">{{
              contact.documentNumber || '—'
            }}</span>
          </td>

          <td class="py-3 px-4">
            <span class="text-sm text-n-slate-11 truncate">{{
              contact.phoneNumber || '—'
            }}</span>
          </td>

          <td class="py-3 px-4">
            <span class="text-sm text-n-slate-11 whitespace-nowrap">
              {{ formatLastActivity(contact.lastActivityAt) }}
            </span>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
