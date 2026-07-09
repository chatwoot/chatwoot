<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVueTable, getCoreRowModel, FlexRender } from '@tanstack/vue-table';

import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import SLACardLabel from 'dashboard/components-next/Conversation/Sla/SLACardLabel.vue';
import CrmTableCellEditable from './CrmTableCellEditable.vue';
import {
  buildCrmCardColumns,
  formatMoneyCents,
  toDate,
} from './cardColumns.js';
import { relativeTimeFromISO } from 'shared/helpers/timeHelper';

const props = defineProps({
  cards: {
    type: Array,
    default: () => [],
  },
  stages: {
    type: Array,
    default: () => [],
  },
  owners: {
    type: Array,
    default: () => [],
  },
  loading: {
    type: Boolean,
    default: false,
  },
  error: {
    type: Boolean,
    default: false,
  },
  // { id: String, desc: Boolean } | null
  sort: {
    type: Object,
    default: null,
  },
  // 'none' | 'stage' | 'owner'
  groupBy: {
    type: String,
    default: 'none',
  },
  // { columnVisibility:{}, columnOrder:[], columnSizing:{}, density:'comfortable'|'compact' }
  columnState: {
    type: Object,
    default: () => ({}),
  },
  // selected card ids (current page)
  selectedIds: {
    type: Array,
    default: () => [],
  },
  // collapsed group keys
  collapsedGroups: {
    type: Array,
    default: () => [],
  },
  // total count for footer / load-more affordance
  totalCount: {
    type: Number,
    default: 0,
  },
  hasMore: {
    type: Boolean,
    default: false,
  },
  // distinguishes empty-no-results (filters active) vs empty-no-cards
  hasActiveFilters: {
    type: Boolean,
    default: false,
  },
  // append the Meta conversion column (only for CTWA-active accounts)
  showMetaColumn: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'sortChange',
  'groupChange',
  'columnChange',
  'selectChange',
  'openCard',
  'editSave',
  'retry',
  'clearFilters',
  'pageChange',
]);

const { t } = useI18n();

const isCompact = computed(() => props.columnState?.density === 'compact');

const cellPadY = computed(() => (isCompact.value ? 'py-1.5' : 'py-3'));
const cellPadX = 'px-4';

/* -------------------------------------------------------------------------- */
/* TanStack table instance                                                    */
/* -------------------------------------------------------------------------- */

const columns = computed(() =>
  buildCrmCardColumns({
    t,
    stages: props.stages,
    agents: props.owners,
    includeMeta: props.showMetaColumn,
  })
);

// Meta conversion badge: maps ledger status -> i18n label + pill classes.
const META_STATUS_LABELS = {
  accepted: 'CRM_KANBAN.META_SYNC_STATUS.LABEL_ACCEPTED',
  pending: 'CRM_KANBAN.META_SYNC_STATUS.LABEL_PENDING',
  skipped: 'CRM_KANBAN.META_SYNC_STATUS.LABEL_SKIPPED',
  error: 'CRM_KANBAN.META_SYNC_STATUS.LABEL_ERROR',
};
const META_STATUS_CLASSES = {
  accepted: 'bg-n-teal-3 text-n-teal-11',
  pending: 'bg-n-amber-3 text-n-amber-11',
  skipped: 'bg-n-alpha-2 text-n-slate-11',
  error: 'bg-n-ruby-3 text-n-ruby-11',
};
const metaStatusLabel = status =>
  META_STATUS_LABELS[status] ? t(META_STATUS_LABELS[status]) : null;
const metaStatusClass = status =>
  META_STATUS_CLASSES[status] || 'bg-n-alpha-2 text-n-slate-11';

const sortingState = computed(() =>
  props.sort?.id ? [{ id: props.sort.id, desc: !!props.sort.desc }] : []
);

const rowSelectionState = computed(() => {
  const map = {};
  props.selectedIds.forEach(id => {
    map[String(id)] = true;
  });
  return map;
});

const table = useVueTable({
  get data() {
    return props.cards;
  },
  get columns() {
    return columns.value;
  },
  state: {
    get sorting() {
      return sortingState.value;
    },
    get columnVisibility() {
      return props.columnState?.columnVisibility || {};
    },
    get columnOrder() {
      return props.columnState?.columnOrder || [];
    },
    get columnSizing() {
      return props.columnState?.columnSizing || {};
    },
    get rowSelection() {
      return rowSelectionState.value;
    },
  },
  getRowId: row => String(row.id),
  manualSorting: true,
  enableColumnResizing: true,
  columnResizeMode: 'onChange',
  enableRowSelection: true,
  getCoreRowModel: getCoreRowModel(),
  // Column resizing happens here; forward the new sizing to the parent so it can
  // persist into listPrefs.columnSizing (column show/hide/order come from the
  // sibling settings menu via the same `columnChange` contract).
  onColumnSizingChange: updater => {
    const current = props.columnState?.columnSizing || {};
    const next = typeof updater === 'function' ? updater(current) : updater;
    emit('columnChange', { columnSizing: next });
  },
});

/* -------------------------------------------------------------------------- */
/* Sorting (server-side, manual) — emit intent, parent owns the source of truth */
/* -------------------------------------------------------------------------- */

const onHeaderSort = column => {
  if (!column.getCanSort()) return;
  const current = props.sort;
  let next;
  if (!current || current.id !== column.id) {
    next = { id: column.id, desc: false };
  } else if (current.desc === false) {
    next = { id: column.id, desc: true };
  } else {
    next = null; // asc -> desc -> none
  }
  emit('sortChange', next);
};

const sortIconFor = column => {
  if (props.sort?.id !== column.id) return 'i-lucide-chevrons-up-down';
  return props.sort.desc ? 'i-lucide-chevron-down' : 'i-lucide-chevron-up';
};

// WCAG 4.1.2: expose the active sort state on the header cell.
const ariaSortFor = column => {
  if (props.sort?.id !== column.id) return 'none';
  return props.sort.desc ? 'descending' : 'ascending';
};

const columnHeaderLabel = column => {
  const header = column.columnDef?.header;
  return typeof header === 'string' ? header : column.id;
};

const sortAriaLabel = column =>
  t('CRM_KANBAN.LIST.SORT_BY', { column: columnHeaderLabel(column) });

/* -------------------------------------------------------------------------- */
/* Selection                                                                  */
/* -------------------------------------------------------------------------- */

const allVisibleIds = computed(() => props.cards.map(c => String(c.id)));

const allSelected = computed(
  () =>
    allVisibleIds.value.length > 0 &&
    allVisibleIds.value.every(id => props.selectedIds.map(String).includes(id))
);

const someSelected = computed(
  () =>
    !allSelected.value &&
    props.selectedIds.some(id => allVisibleIds.value.includes(String(id)))
);

const toggleSelectAll = () => {
  emit('selectChange', allSelected.value ? [] : [...allVisibleIds.value]);
};

const isRowSelected = id => props.selectedIds.map(String).includes(String(id));

const toggleRow = id => {
  const sid = String(id);
  const set = new Set(props.selectedIds.map(String));
  if (set.has(sid)) set.delete(sid);
  else set.add(sid);
  emit('selectChange', Array.from(set));
};

/* -------------------------------------------------------------------------- */
/* Group-by (client-side derivation from props.cards — no cached state, so     */
/* realtime upserts into the list stay in sync, per manifest R4)               */
/* -------------------------------------------------------------------------- */

const groupKeyFor = card => {
  if (props.groupBy === 'stage') return String(card.stage_id ?? 'none');
  if (props.groupBy === 'owner') return String(card.owner_id ?? 'none');
  return 'all';
};

const groupLabelFor = key => {
  if (props.groupBy === 'stage') {
    if (key === 'none') return t('CRM_KANBAN.DRAWER.EMPTY_VALUE');
    const stage = props.stages.find(s => String(s.id) === key);
    return stage?.name || t('CRM_KANBAN.DRAWER.EMPTY_VALUE');
  }
  if (props.groupBy === 'owner') {
    if (key === 'none') return t('CRM_KANBAN.CARD.NO_OWNER');
    const owner = props.owners.find(a => String(a.id) === key);
    return (
      owner?.name || owner?.available_name || t('CRM_KANBAN.CARD.NO_OWNER')
    );
  }
  return '';
};

const groupColorFor = key => {
  if (props.groupBy !== 'stage' || key === 'none') return null;
  const stage = props.stages.find(s => String(s.id) === key);
  return stage?.color || null;
};

// [{ key, label, color, count, sumCents, currency, collapsed, rows: row[] }]
const groupedRows = computed(() => {
  const rows = table.getRowModel().rows;
  if (props.groupBy === 'none') {
    return [{ key: 'all', isGroup: false, rows }];
  }
  const map = new Map();
  rows.forEach(row => {
    const key = groupKeyFor(row.original);
    if (!map.has(key)) map.set(key, []);
    map.get(key).push(row);
  });
  return Array.from(map.entries()).map(([key, groupRows]) => {
    const sumCents = groupRows.reduce(
      (acc, r) => acc + Number(r.original.value_cents || 0),
      0
    );
    const currency = groupRows[0]?.original?.currency || 'BRL';
    return {
      key,
      isGroup: true,
      label: groupLabelFor(key),
      color: groupColorFor(key),
      count: groupRows.length,
      sumCents,
      currency,
      collapsed: props.collapsedGroups.map(String).includes(String(key)),
      rows: groupRows,
    };
  });
});

const toggleGroup = key => {
  const set = new Set(props.collapsedGroups.map(String));
  const sid = String(key);
  if (set.has(sid)) set.delete(sid);
  else set.add(sid);
  emit('groupChange', { groupBy: props.groupBy, collapsed: Array.from(set) });
};

const groupTotalLabel = group =>
  t('CRM_KANBAN.LIST.GROUP_TOTAL', {
    count: group.count,
    value: formatMoneyCents(
      group.sumCents,
      group.currency,
      formatMoneyCents(0)
    ),
  });

/* -------------------------------------------------------------------------- */
/* Read-only cell formatting helpers                                          */
/* -------------------------------------------------------------------------- */

const formatDate = value => {
  const d = toDate(value);
  if (!d) return t('CRM_KANBAN.FOLLOW_UP_FILTER.NONE');
  return new Intl.DateTimeFormat('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(d);
};

const followUpClass = card => {
  const d = toDate(card.next_follow_up_at);
  if (!d) return 'text-n-slate-10';
  return d < new Date() ? 'text-n-ruby-11' : 'text-n-teal-11';
};

const relativeDate = value => {
  const d = toDate(value);
  if (!d) return t('CRM_KANBAN.FOLLOW_UP_FILTER.NONE');
  return relativeTimeFromISO(d.toISOString());
};

const contactSubtitle = card =>
  card.contact?.name ||
  card.contact?.phone_number ||
  t('CRM_KANBAN.CARD.STANDALONE');

const stageForCard = card =>
  card.stage ||
  props.stages.find(s => Number(s.id) === Number(card.stage_id)) ||
  null;

const ownerName = card => card.owner?.name || t('CRM_KANBAN.CARD.NO_OWNER');

// SLACardLabel expects the conversation-list "chat" shape; card.conversation
// already carries applied_sla + epoch fields from the payload builder.
const slaChatFor = card => {
  const conversation = card?.conversation;
  if (!conversation?.applied_sla) return null;
  return {
    applied_sla: conversation.applied_sla,
    first_reply_created_at: conversation.first_reply_created_at,
    waiting_since: conversation.waiting_since,
    status: conversation.status,
  };
};

const isEditable = column => !!column.columnDef.meta?.editable;
const cellKind = column => column.columnDef.meta?.kind;
const ALIGN_CLASS = {
  right: 'text-right',
  center: 'text-center',
  left: 'text-left',
};
const cellAlign = column =>
  ALIGN_CLASS[column.columnDef.meta?.align] || ALIGN_CLASS.left;
const isFrozen = column => !!column.columnDef.meta?.frozen;

const onEditSave = (card, field, value) => {
  emit('editSave', { cardId: card.id, field, value });
};

/* -------------------------------------------------------------------------- */
/* States                                                                     */
/* -------------------------------------------------------------------------- */

const isEmpty = computed(
  () => !props.loading && !props.error && props.cards.length === 0
);

const skeletonRows = Array.from({ length: 8 }, (_, i) => i);

const visibleLeafColumns = computed(() => table.getVisibleLeafColumns());
const colSpan = computed(() => visibleLeafColumns.value.length || 1);

// Cumulative left offset (px) for a frozen/pinned column = sum of the widths of
// the frozen columns before it. Without this, every frozen cell pinned to left:0
// and stacked on top of the previous one, leaving their real column band uncovered
// so horizontally-scrolled cells bled through.
const frozenLeft = column => {
  const cols = visibleLeafColumns.value;
  const index = cols.findIndex(col => col.id === column.id);
  return cols
    .slice(0, index < 0 ? 0 : index)
    .filter(isFrozen)
    .reduce((sum, col) => sum + col.getSize(), 0);
};

/* -------------------------------------------------------------------------- */
/* Keyboard grid navigation (roving tabindex)                                 */
/* ArrowUp/Down move row focus, Enter opens the card, Esc clears selection.   */
/* -------------------------------------------------------------------------- */

const gridRef = ref(null);

// Flat, render-order list of the focusable (visible, non-collapsed) row ids.
const navigableRowIds = computed(() =>
  groupedRows.value
    .filter(group => !group.collapsed)
    .flatMap(group => group.rows.map(row => String(row.original.id)))
);

const activeRowId = ref(null);

const ensureActiveRow = () => {
  const ids = navigableRowIds.value;
  if (!ids.length) {
    activeRowId.value = null;
    return null;
  }
  if (!activeRowId.value || !ids.includes(activeRowId.value)) {
    [activeRowId.value] = ids;
  }
  return activeRowId.value;
};

// Roving tabindex: only the active row is in the tab order (0), the rest -1.
const rowTabIndex = id => {
  const ids = navigableRowIds.value;
  const active =
    activeRowId.value && ids.includes(activeRowId.value)
      ? activeRowId.value
      : ids[0];
  return String(id) === String(active) ? 0 : -1;
};

const focusRow = id => {
  activeRowId.value = String(id);
  const el = gridRef.value?.querySelector(`[data-row-id="${id}"]`);
  if (el) el.focus();
};

const moveActiveRow = delta => {
  const ids = navigableRowIds.value;
  if (!ids.length) return;
  const current = ensureActiveRow();
  const index = ids.indexOf(current);
  const next = Math.min(Math.max(index + delta, 0), ids.length - 1);
  focusRow(ids[next]);
};

const onRowFocus = id => {
  activeRowId.value = String(id);
};

const onRowKeydown = (event, card) => {
  switch (event.key) {
    case 'ArrowDown':
      event.preventDefault();
      moveActiveRow(1);
      break;
    case 'ArrowUp':
      event.preventDefault();
      moveActiveRow(-1);
      break;
    case 'Enter':
      event.preventDefault();
      emit('openCard', card);
      break;
    case 'Escape':
      event.preventDefault();
      emit('selectChange', []);
      break;
    default:
      break;
  }
};
</script>

<template>
  <div class="flex h-full min-h-0 flex-col">
    <!-- ERROR -->
    <div
      v-if="error"
      class="flex h-full min-h-0 flex-1 items-center justify-center px-6 text-center"
    >
      <div class="flex flex-col items-center gap-3">
        <span class="i-lucide-triangle-alert size-8 text-n-ruby-11" />
        <p class="mb-0 text-sm text-n-slate-11">
          {{ t('CRM_KANBAN.LIST.RETRY') }}
        </p>
        <Button
          :label="t('CRM_KANBAN.LIST.RETRY')"
          icon="i-lucide-refresh-cw"
          size="sm"
          variant="outline"
          @click="emit('retry')"
        />
      </div>
    </div>

    <!-- EMPTY (no results vs no cards) -->
    <div
      v-else-if="isEmpty"
      class="flex h-full min-h-0 flex-1 items-center justify-center px-6 text-center"
    >
      <div class="flex flex-col items-center gap-2">
        <span
          class="i-lucide-inbox size-8 text-n-slate-10"
          aria-hidden="true"
        />
        <p class="mb-0 text-sm font-medium text-n-slate-12">
          {{
            hasActiveFilters
              ? t('CRM_KANBAN.LIST.EMPTY_NO_RESULTS')
              : t('CRM_KANBAN.LIST.EMPTY_TITLE')
          }}
        </p>
        <p class="mb-0 text-xs text-n-slate-11">
          {{ t('CRM_KANBAN.LIST.EMPTY_HELP') }}
        </p>
        <Button
          v-if="hasActiveFilters"
          :label="t('CRM_KANBAN.LIST.EMPTY_NO_RESULTS_CTA')"
          icon="i-lucide-filter-x"
          size="sm"
          variant="outline"
          class="mt-1"
          @click="emit('clearFilters')"
        />
      </div>
    </div>

    <!-- TABLE (md and up) -->
    <div
      v-else
      class="hidden min-h-0 flex-1 overflow-auto md:block"
      role="region"
      :aria-busy="loading"
    >
      <table
        ref="gridRef"
        role="grid"
        class="w-full border-separate border-spacing-0 text-sm"
      >
        <thead role="rowgroup" class="sticky top-0 z-20">
          <tr
            v-for="headerGroup in table.getHeaderGroups()"
            :key="headerGroup.id"
            role="row"
          >
            <th
              v-for="header in headerGroup.headers"
              :key="header.id"
              scope="col"
              role="columnheader"
              :aria-sort="ariaSortFor(header.column)"
              :style="{
                width: `${header.getSize()}px`,
                ...(isFrozen(header.column)
                  ? { left: `${frozenLeft(header.column)}px` }
                  : {}),
              }"
              class="relative border-b border-n-weak bg-n-alpha-black2 font-medium text-n-slate-11"
              :class="[
                cellPadX,
                cellPadY,
                cellAlign(header.column),
                isFrozen(header.column) ? 'sticky z-30 bg-n-surface-2' : '',
              ]"
            >
              <!-- select header = page-level select-all checkbox -->
              <div
                v-if="cellKind(header.column) === 'select'"
                class="flex items-center justify-center"
              >
                <Checkbox
                  :model-value="allSelected"
                  :indeterminate="someSelected"
                  :aria-label="t('CRM_KANBAN.LIST.SELECT_ALL')"
                  @change="toggleSelectAll"
                />
              </div>
              <button
                v-else-if="header.column.getCanSort()"
                type="button"
                class="flex w-full items-center gap-1 text-xs uppercase tracking-wide"
                :class="
                  cellAlign(header.column) === 'text-right'
                    ? 'justify-end'
                    : 'justify-start'
                "
                :aria-label="sortAriaLabel(header.column)"
                @click="onHeaderSort(header.column)"
              >
                <FlexRender
                  :render="header.column.columnDef.header"
                  :props="header.getContext()"
                />
                <span
                  :class="sortIconFor(header.column)"
                  class="size-3.5 text-n-slate-10"
                  aria-hidden="true"
                />
              </button>
              <span v-else class="block text-xs uppercase tracking-wide">
                <FlexRender
                  :render="header.column.columnDef.header"
                  :props="header.getContext()"
                />
              </span>

              <!-- resize handle -->
              <span
                v-if="header.column.getCanResize()"
                class="absolute top-0 ltr:right-0 rtl:left-0 z-40 h-full w-1 cursor-col-resize select-none touch-none bg-transparent hover:bg-n-brand/40"
                :class="header.column.getIsResizing() ? 'bg-n-brand' : ''"
                @mousedown="header.getResizeHandler()($event)"
                @touchstart="header.getResizeHandler()($event)"
              />
            </th>
          </tr>
        </thead>

        <tbody role="rowgroup">
          <!-- SKELETON -->
          <template v-if="loading">
            <tr v-for="n in skeletonRows" :key="`sk-${n}`" role="row">
              <td
                v-for="col in visibleLeafColumns"
                :key="col.id"
                role="gridcell"
                class="border-b border-n-weak"
                :class="[cellPadX, cellPadY]"
              >
                <div class="h-3.5 w-full animate-pulse rounded bg-n-alpha-2" />
              </td>
            </tr>
          </template>

          <!-- GROUPED / FLAT ROWS -->
          <template v-else>
            <template v-for="group in groupedRows" :key="group.key">
              <!-- group header row -->
              <tr v-if="group.isGroup" role="row">
                <td
                  role="gridcell"
                  :colspan="colSpan"
                  class="border-b border-n-weak bg-n-alpha-2"
                  :class="[cellPadX]"
                >
                  <button
                    type="button"
                    class="flex w-full items-center gap-2 py-2 text-left"
                    @click="toggleGroup(group.key)"
                  >
                    <span
                      :class="
                        group.collapsed
                          ? 'i-lucide-chevron-right'
                          : 'i-lucide-chevron-down'
                      "
                      class="size-4 text-n-slate-11"
                      aria-hidden="true"
                    />
                    <span
                      v-if="group.color"
                      class="size-2.5 rounded-full"
                      :style="{ backgroundColor: group.color }"
                    />
                    <span class="text-sm font-medium text-n-slate-12">
                      {{ group.label }}
                    </span>
                    <span class="text-xs text-n-slate-11">
                      {{ groupTotalLabel(group) }}
                    </span>
                  </button>
                </td>
              </tr>

              <!-- data rows -->
              <template v-if="!group.collapsed">
                <tr
                  v-for="row in group.rows"
                  :key="row.id"
                  role="row"
                  :data-row-id="row.original.id"
                  :tabindex="rowTabIndex(row.original.id)"
                  :aria-selected="isRowSelected(row.original.id)"
                  class="group/row transition-colors hover:bg-n-alpha-2 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-n-brand"
                  :class="isRowSelected(row.original.id) ? 'bg-n-brand/5' : ''"
                  @focus="onRowFocus(row.original.id)"
                  @keydown="onRowKeydown($event, row.original)"
                >
                  <td
                    v-for="cell in row.getVisibleCells()"
                    :key="cell.id"
                    role="gridcell"
                    :style="{
                      width: `${cell.column.getSize()}px`,
                      ...(isFrozen(cell.column)
                        ? { left: `${frozenLeft(cell.column)}px` }
                        : {}),
                    }"
                    class="border-b border-n-weak align-middle"
                    :class="[
                      cellPadX,
                      cellPadY,
                      cellAlign(cell.column),
                      isFrozen(cell.column)
                        ? 'sticky z-10 bg-n-surface-2 group-hover/row:bg-n-solid-1'
                        : '',
                    ]"
                  >
                    <!-- SELECT -->
                    <div
                      v-if="cellKind(cell.column) === 'select'"
                      class="flex items-center justify-center"
                    >
                      <Checkbox
                        :model-value="isRowSelected(row.original.id)"
                        :aria-label="
                          t('CRM_KANBAN.LIST.SELECT_ROW', {
                            name: row.original.title || row.original.id,
                          })
                        "
                        @change="toggleRow(row.original.id)"
                      />
                    </div>

                    <!-- TITLE (frozen, opens drawer) -->
                    <button
                      v-else-if="cellKind(cell.column) === 'title'"
                      type="button"
                      class="flex min-w-0 flex-col text-left"
                      @click="emit('openCard', row.original)"
                    >
                      <span
                        class="truncate font-medium text-n-slate-12 hover:underline"
                      >
                        {{ row.original.title }}
                      </span>
                      <span class="truncate text-xs text-n-slate-11">
                        {{ contactSubtitle(row.original) }}
                      </span>
                    </button>

                    <!-- EDITABLE cells delegate to sibling component -->
                    <CrmTableCellEditable
                      v-else-if="isEditable(cell.column)"
                      :card="row.original"
                      :field="cell.column.columnDef.meta.field"
                      :stages="stages"
                      :owners="owners"
                      @save="
                        value =>
                          onEditSave(
                            row.original,
                            cell.column.columnDef.meta.field,
                            value
                          )
                      "
                    />

                    <!-- READ-ONLY renderers -->
                    <span
                      v-else-if="cellKind(cell.column) === 'responsible'"
                      class="flex min-w-0 items-center gap-2"
                    >
                      <Avatar
                        v-if="row.original.responsible?.name"
                        :name="row.original.responsible.name"
                        :size="20"
                      />
                      <span class="truncate text-n-slate-11">
                        {{
                          row.original.responsible?.name ||
                          t('CRM_KANBAN.CARD.NO_OWNER')
                        }}
                      </span>
                    </span>

                    <span
                      v-else-if="cellKind(cell.column) === 'inbox'"
                      class="block truncate text-n-slate-11"
                    >
                      {{
                        row.original.inbox?.name ||
                        t('CRM_KANBAN.CARD.NO_INBOX')
                      }}
                    </span>

                    <span
                      v-else-if="cellKind(cell.column) === 'lastActivity'"
                      class="block truncate text-n-slate-11"
                    >
                      {{ relativeDate(row.original.last_activity_at) }}
                    </span>

                    <span
                      v-else-if="cellKind(cell.column) === 'priority'"
                      class="block truncate text-n-slate-11"
                    >
                      {{
                        row.original.priority ||
                        t('CRM_KANBAN.DRAWER.EMPTY_VALUE')
                      }}
                    </span>

                    <template v-else-if="cellKind(cell.column) === 'sla'">
                      <SLACardLabel
                        v-if="slaChatFor(row.original)"
                        :chat="slaChatFor(row.original)"
                      />
                      <span v-else class="text-n-slate-10">—</span>
                    </template>

                    <button
                      v-else-if="cellKind(cell.column) === 'conversation'"
                      type="button"
                      class="flex items-center gap-1 truncate text-n-brand hover:underline"
                      @click="emit('openCard', row.original)"
                    >
                      <span class="i-lucide-message-square size-3.5" />
                      <span class="truncate">
                        {{
                          row.original.conversation?.display_id
                            ? `#${row.original.conversation.display_id}`
                            : t('CRM_KANBAN.DRAWER.EMPTY_VALUE')
                        }}
                      </span>
                    </button>

                    <!-- Meta conversion status badge -->
                    <span
                      v-else-if="cellKind(cell.column) === 'meta'"
                      class="block truncate"
                    >
                      <span
                        v-if="
                          metaStatusLabel(row.original.meta_conversion?.status)
                        "
                        class="inline-flex rounded-md px-2 py-1 text-[11px]"
                        :class="
                          metaStatusClass(row.original.meta_conversion?.status)
                        "
                        :title="t('CRM_KANBAN.META_SYNC_STATUS.COLUMN_TOOLTIP')"
                      >
                        {{
                          metaStatusLabel(row.original.meta_conversion?.status)
                        }}
                      </span>
                      <span v-else class="text-n-slate-10">
                        {{ t('CRM_KANBAN.META_SYNC_STATUS.NONE') }}
                      </span>
                    </span>

                    <!-- fallback: raw accessor value -->
                    <span v-else class="block truncate text-n-slate-11">
                      <FlexRender
                        :render="cell.column.columnDef.cell"
                        :props="cell.getContext()"
                      />
                    </span>
                  </td>
                </tr>
              </template>
            </template>
          </template>
        </tbody>
      </table>
    </div>

    <!-- RESPONSIVE CARD LIST (below md) -->
    <div
      v-if="!error && !isEmpty"
      class="min-h-0 flex-1 overflow-auto md:hidden"
    >
      <div v-if="loading" class="flex items-center justify-center py-10">
        <Spinner />
      </div>
      <ul v-else class="divide-y divide-n-weak">
        <li
          v-for="card in cards"
          :key="`m-${card.id}`"
          class="flex items-start gap-3 px-4 py-3"
        >
          <Checkbox
            :model-value="isRowSelected(card.id)"
            :aria-label="
              t('CRM_KANBAN.LIST.SELECT_ROW', { name: card.title || card.id })
            "
            class="mt-1"
            @change="toggleRow(card.id)"
          />
          <button
            type="button"
            class="flex min-w-0 flex-1 flex-col text-left"
            @click="emit('openCard', card)"
          >
            <span class="truncate font-medium text-n-slate-12">
              {{ card.title }}
            </span>
            <span class="truncate text-xs text-n-slate-11">
              {{ contactSubtitle(card) }}
            </span>
            <div class="mt-1 flex flex-wrap items-center gap-2 text-xs">
              <span
                v-if="stageForCard(card)"
                class="rounded px-1.5 py-0.5"
                :style="{
                  backgroundColor: stageForCard(card)?.color
                    ? `${stageForCard(card).color}22`
                    : undefined,
                }"
              >
                {{ stageForCard(card)?.name }}
              </span>
              <span class="text-n-slate-11">{{ ownerName(card) }}</span>
              <span :class="followUpClass(card)">
                {{ formatDate(card.next_follow_up_at) }}
              </span>
            </div>
          </button>
          <span class="shrink-0 text-right text-sm font-medium text-n-slate-12">
            {{
              formatMoneyCents(
                card.value_cents,
                card.currency,
                formatMoneyCents(0)
              )
            }}
          </span>
        </li>
      </ul>
    </div>

    <!-- FOOTER: count + load more -->
    <div
      v-if="!error && !isEmpty"
      class="flex items-center justify-between border-t border-n-weak px-4 py-2"
    >
      <p class="mb-0 text-xs text-n-slate-10">
        {{ t('CRM_KANBAN.LIST.META', { count: totalCount || cards.length }) }}
      </p>
      <Button
        v-if="hasMore"
        :label="t('CRM_KANBAN.ACTIONS.LOAD_MORE')"
        icon="i-lucide-chevron-down"
        size="sm"
        variant="ghost"
        :is-loading="loading"
        @click="emit('pageChange')"
      />
    </div>
  </div>
</template>
