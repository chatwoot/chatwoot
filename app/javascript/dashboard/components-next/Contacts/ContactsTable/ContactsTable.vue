<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { formatAttributeValue } from 'dashboard/composables/useFeaturedAttributes';
import { dynamicTime } from 'shared/helpers/timeHelper';
import {
  STANDARD_CONTACT_COLUMNS,
  buildCustomColumns,
  resolveVisibleColumns,
  isCustomColumnKey,
  attributeKeyFromColumn,
} from 'dashboard/helper/contactTableColumns';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import ContactTableLabels from 'dashboard/components-next/Contacts/ContactsTable/ContactTableLabels.vue';

// Must match checkbox column width (padding + control) so name sticky offset aligns
const CHECKBOX_COL_WIDTH = '2.75rem';
const EMPTY = '--';

const props = defineProps({
  contacts: { type: Array, required: true },
  selectedContactIds: { type: Array, default: () => [] },
  activeSort: { type: String, default: 'last_activity_at' },
  activeOrdering: { type: String, default: '' },
});

const emit = defineEmits(['toggleContact', 'showContact', 'update:sort']);

const { t } = useI18n();
const { uiSettings } = useUISettings();
const getAttributesByModel = useMapGetter('attributes/getAttributesByModel');

const contactAttributeDefs = computed(() => {
  const getter = getAttributesByModel.value;
  return typeof getter === 'function' ? getter('contact_attribute') || [] : [];
});

const customColumns = computed(() =>
  buildCustomColumns(contactAttributeDefs.value)
);

const columnByKey = computed(() => {
  const map = {};
  STANDARD_CONTACT_COLUMNS.forEach(col => {
    map[col.key] = {
      ...col,
      label: t(`CONTACTS_LAYOUT.TABLE.COLUMNS.${col.labelKey}`),
    };
  });
  customColumns.value.forEach(col => {
    map[col.key] = col;
  });
  return map;
});

const visibleColumnKeys = computed(() =>
  resolveVisibleColumns(
    uiSettings.value?.contacts_table_columns,
    Object.keys(columnByKey.value),
    customColumns.value
  )
);

const visibleColumns = computed(() =>
  visibleColumnKeys.value.map(key => columnByKey.value[key]).filter(Boolean)
);

/** Force header/body cells to remount when column sequence changes */
const columnsOrderKey = computed(() => visibleColumnKeys.value.join('|'));

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

const isSortedBy = key => {
  const col = columnByKey.value[key];
  return col?.sortKey ? props.activeSort === col.sortKey : false;
};

const sortIcon = key => {
  if (!isSortedBy(key)) return 'i-lucide-arrow-up-down';
  return props.activeOrdering === '-'
    ? 'i-lucide-arrow-down'
    : 'i-lucide-arrow-up';
};

const handleHeaderClick = column => {
  if (!column.sortable || !column.sortKey) return;
  const isSame = props.activeSort === column.sortKey;
  let order = '';
  if (isSame) {
    order = props.activeOrdering === '-' ? '' : '-';
  }
  emit('update:sort', { sort: column.sortKey, order });
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

const formatTimestamp = timestamp => {
  if (!timestamp) return EMPTY;
  return dynamicTime(timestamp);
};

const companyName = contact =>
  contact.additionalAttributes?.companyName ||
  contact.additionalAttributes?.company_name ||
  '';

const cityName = contact =>
  contact.additionalAttributes?.city || contact.location || '';

const countryName = contact =>
  contact.additionalAttributes?.country ||
  contact.additionalAttributes?.countryCode ||
  contact.countryCode ||
  '';

const assignedAgentName = contact =>
  contact.assignedAgent?.availableName || contact.assignedAgent?.name || '';

const customAttrValue = (contact, column) => {
  const attrs = contact.customAttributes || contact.custom_attributes || {};
  const key = column.attributeKey || attributeKeyFromColumn(column.key);
  const raw = attrs[key];
  const empty = raw === undefined || raw === null || raw === '';
  if (empty && column.formula) {
    return formatAttributeValue(0, column.displayType);
  }
  if (empty) return EMPTY;
  return formatAttributeValue(raw, column.displayType);
};

const cellText = (contact, column) => {
  switch (column.key) {
    case 'name':
      return contact.name || EMPTY;
    case 'document_number':
      return contact.documentNumber || EMPTY;
    case 'phone_number':
      return contact.phoneNumber || EMPTY;
    case 'email':
      return contact.email || EMPTY;
    case 'identifier':
      return contact.identifier || EMPTY;
    case 'company_name':
      return companyName(contact) || EMPTY;
    case 'city':
      return cityName(contact) || EMPTY;
    case 'country':
      return countryName(contact) || EMPTY;
    case 'created_at':
      return formatTimestamp(contact.createdAt);
    case 'last_activity_at':
      return formatTimestamp(contact.lastActivityAt);
    case 'blocked':
      return contact.blocked
        ? t('CONTACTS_LAYOUT.TABLE.COLUMNS.BLOCKED_YES')
        : t('CONTACTS_LAYOUT.TABLE.COLUMNS.BLOCKED_NO');
    default:
      if (isCustomColumnKey(column.key)) return customAttrValue(contact, column);
      return EMPTY;
  }
};

const columnClass = column => {
  if (column.key === 'name') return 'w-[14rem] min-w-[14rem] max-w-[14rem]';
  if (column.key === 'labels') return 'min-w-[16rem]';
  if (column.key === 'assigned_agent') return 'min-w-[10rem]';
  if (column.key === 'email') return 'min-w-[12rem]';
  if (column.key === 'phone_number') return 'min-w-[9rem]';
  if (column.key === 'last_activity_at' || column.key === 'created_at') {
    return 'min-w-[8.5rem]';
  }
  if (column.numeric) return 'min-w-[8rem] text-end';
  return 'min-w-[8rem]';
};

// Solid backgrounds only — sticky cells cannot use alpha or content shows through
const rowCellBg = contact => {
  if (selectedIdsSet.value.has(contact.id)) {
    return 'bg-n-slate-3 dark:bg-n-solid-3 group-hover:bg-n-slate-4 dark:group-hover:bg-n-solid-3';
  }
  return 'bg-n-surface-1 group-hover:bg-n-slate-2 dark:group-hover:bg-n-solid-2';
};

const stickyCheckboxStyle = {
  left: '0',
  width: CHECKBOX_COL_WIDTH,
  minWidth: CHECKBOX_COL_WIDTH,
  maxWidth: CHECKBOX_COL_WIDTH,
};
const stickyNameStyle = { left: CHECKBOX_COL_WIDTH };
</script>

<template>
  <div
    class="relative z-0 flex min-h-0 w-full flex-1 flex-col overflow-auto rounded-xl border border-n-weak"
  >
    <table
      :key="columnsOrderKey"
      class="w-max min-w-full border-separate border-spacing-0"
    >
      <thead>
        <tr>
          <th
            class="sticky top-0 left-0 z-[3] border-b border-n-weak bg-n-surface-2 py-2 px-3 text-start"
            :style="stickyCheckboxStyle"
          >
            <Checkbox
              :model-value="allSelected"
              :indeterminate="someSelected"
              :title="selectPageTitle"
              @change="event => toggleSelectAll(event.target.checked)"
            />
          </th>
          <th
            v-for="column in visibleColumns"
            :key="column.key"
            class="sticky top-0 z-[2] border-b border-n-weak bg-n-surface-2 py-2 px-3 text-start text-xs font-semibold text-n-slate-11 uppercase tracking-wide select-none whitespace-nowrap"
            :class="[
              columnClass(column),
              column.sortable
                ? 'cursor-pointer hover:text-n-slate-12'
                : 'cursor-default',
              column.key === 'name'
                ? 'z-[3] shadow-[4px_0_8px_-4px_rgba(0,0,0,0.12)]'
                : '',
            ]"
            :style="column.key === 'name' ? stickyNameStyle : undefined"
            @click="handleHeaderClick(column)"
          >
            <span class="inline-flex items-center gap-1.5">
              {{ column.label }}
              <span
                v-if="column.sortable"
                class="size-3.5 shrink-0"
                :class="[
                  sortIcon(column.key),
                  isSortedBy(column.key) ? 'text-n-brand' : 'text-n-slate-9',
                ]"
              />
            </span>
          </th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="contact in contacts"
          :key="contact.id"
          role="button"
          tabindex="0"
          class="group cursor-pointer transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-n-brand"
          @click="onClickViewDetails(contact.id)"
          @keydown="onRowKeydown($event, contact.id)"
        >
          <td
            class="sticky left-0 z-[1] border-b border-n-weak py-1.5 px-3"
            :class="rowCellBg(contact)"
            :style="stickyCheckboxStyle"
            @click.stop
          >
            <Checkbox
              :model-value="selectedIdsSet.has(contact.id)"
              @change="event => toggleContact(contact.id, event.target.checked)"
            />
          </td>
          <td
            v-for="column in visibleColumns"
            :key="`${contact.id}-${column.key}`"
            class="border-b border-n-weak py-1.5 px-3"
            :class="[
              columnClass(column),
              rowCellBg(contact),
              column.key === 'name'
                ? 'sticky z-[1] shadow-[4px_0_8px_-4px_rgba(0,0,0,0.08)]'
                : '',
            ]"
            :style="column.key === 'name' ? stickyNameStyle : undefined"
          >
            <template v-if="column.key === 'name'">
              <div class="flex items-center gap-2 min-w-0">
                <Avatar
                  :name="contact.name"
                  :src="contact.thumbnail"
                  :size="24"
                  hide-offline-status
                  class="shrink-0"
                />
                <div class="flex flex-col min-w-0 gap-0">
                  <span
                    class="text-sm font-medium text-n-slate-12 truncate leading-tight"
                    :title="contact.name || ''"
                  >
                    {{ contact.name || EMPTY }}
                  </span>
                  <span
                    v-if="
                      companyName(contact) &&
                      !visibleColumns.some(c => c.key === 'company_name')
                    "
                    class="text-xs text-n-slate-10 truncate leading-tight"
                    :title="companyName(contact)"
                  >
                    {{ companyName(contact) }}
                  </span>
                </div>
              </div>
            </template>
            <template v-else-if="column.key === 'labels'">
              <div @click.stop>
                <ContactTableLabels :label-titles="contact.labels || []" />
              </div>
            </template>
            <template v-else-if="column.key === 'assigned_agent'">
              <div
                v-if="assignedAgentName(contact)"
                class="flex items-center gap-2 min-w-0"
              >
                <Avatar
                  :name="assignedAgentName(contact)"
                  :src="contact.assignedAgent?.thumbnail"
                  :size="20"
                  hide-offline-status
                  class="shrink-0"
                />
                <span
                  class="text-sm text-n-slate-12 truncate"
                  :title="assignedAgentName(contact)"
                >
                  {{ assignedAgentName(contact) }}
                </span>
              </div>
              <span v-else class="text-sm text-n-slate-10">{{ EMPTY }}</span>
            </template>
            <span
              v-else
              class="text-sm text-n-slate-12 truncate block leading-snug"
              :class="column.numeric ? 'tabular-nums' : ''"
              :title="String(cellText(contact, column))"
            >
              {{ cellText(contact, column) }}
            </span>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
