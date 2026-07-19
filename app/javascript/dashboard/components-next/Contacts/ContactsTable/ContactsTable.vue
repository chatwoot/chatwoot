<script setup>
import { computed } from 'vue';

import { useI18n } from 'vue-i18n';

import { dynamicTime } from 'shared/helpers/timeHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

import ContactTableLabels from 'dashboard/components-next/Contacts/ContactsTable/ContactTableLabels.vue';

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

const someSelected = computed(
  () =>
    props.contacts.some(contact => selectedIdsSet.value.has(contact.id)) &&
    !allSelected.value
);

const selectPageTitle = computed(() =>
  t('CONTACTS_LAYOUT.TABLE.SELECT_PAGE', { count: props.contacts.length })
);

const TABLE_COLUMNS = [
  {
    key: 'name',
    sortable: true,
    labelKey: 'NAME',
  },
  {
    key: 'document_number',
    sortable: true,
    labelKey: 'IDENTITY',
  },
  {
    key: 'phone_number',
    sortable: true,
    labelKey: 'PHONE',
  },
  {
    key: 'email',
    sortable: true,
    labelKey: 'EMAIL',
  },
  {
    key: 'labels',
    sortable: false,
    labelKey: 'LABELS',
  },
  {
    key: 'assigned_agent',
    sortable: false,
    labelKey: 'ASSIGNED_AGENT',
  },
  {
    key: 'last_activity_at',
    sortable: true,
    labelKey: 'LAST_ACTIVITY',
  },
];

const columnLabel = labelKey => t(`CONTACTS_LAYOUT.TABLE.COLUMNS.${labelKey}`);

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

const toggleSelectAll = shouldSelect => {
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

const assignedAgentName = contact =>
  contact.assignedAgent?.availableName || contact.assignedAgent?.name || '';
</script>

<template>
  <div class="hidden md:block w-full overflow-x-auto">
    <table class="w-full min-w-[56rem] table-auto divide-y divide-n-weak">
      <thead class="border-t border-n-weak bg-n-surface-2">
        <tr>
          <th class="py-2 px-3 w-10">
            <Checkbox
              :model-value="allSelected"
              :indeterminate="someSelected"
              :title="selectPageTitle"
              @change="event => toggleSelectAll(event.target.checked)"
            />
          </th>

          <th
            v-for="column in TABLE_COLUMNS"
            :key="column.key"
            class="py-2 px-3 text-start text-xs font-semibold text-n-slate-11 uppercase tracking-wider select-none"
            :class="
              column.sortable
                ? 'cursor-pointer hover:text-n-slate-12'
                : 'cursor-default'
            "
            @click="column.sortable && handleHeaderClick(column.key)"
          >
            <span class="inline-flex items-center gap-1">
              {{ columnLabel(column.labelKey) }}

              <span
                v-if="column.sortable"
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
          <td class="py-2 px-3" @click.stop>
            <Checkbox
              :model-value="selectedIdsSet.has(contact.id)"
              @change="event => toggleContact(contact.id, event.target.checked)"
            />
          </td>

          <td class="py-2 px-3 max-w-[14rem]">
            <div class="flex items-center gap-2">
              <Avatar
                :name="contact.name"
                :src="contact.thumbnail"
                :size="28"
                hide-offline-status
              />

              <div class="flex flex-col min-w-0">
                <span class="text-sm font-medium text-n-slate-12 truncate">
                  {{ contact.name || '--' }}
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

          <td class="py-2 px-3 max-w-[9rem]">
            <span class="text-sm text-n-slate-11 truncate">{{
              contact.documentNumber || '--'
            }}</span>
          </td>

          <td class="py-2 px-3 max-w-[9rem]">
            <span class="text-sm text-n-slate-11 truncate">{{
              contact.phoneNumber || '--'
            }}</span>
          </td>

          <td class="py-2 px-3 max-w-[12rem]">
            <span class="text-sm text-n-slate-11 truncate">{{
              contact.email || '--'
            }}</span>
          </td>

          <td class="py-2 px-3" @click.stop>
            <ContactTableLabels :label-titles="contact.labels || []" />
          </td>

          <td class="py-2 px-3 max-w-[10rem]">
            <div
              v-if="assignedAgentName(contact)"
              class="flex items-center gap-2 min-w-0"
            >
              <Avatar
                :name="assignedAgentName(contact)"
                :src="contact.assignedAgent?.thumbnail"
                :size="24"
                hide-offline-status
              />
              <span class="text-sm text-n-slate-11 truncate">
                {{ assignedAgentName(contact) }}
              </span>
            </div>
            <span v-else class="text-sm text-n-slate-11">—</span>
          </td>

          <td class="py-2 px-3">
            <span class="text-sm text-n-slate-11 whitespace-nowrap">
              {{ formatLastActivity(contact.lastActivityAt) }}
            </span>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
