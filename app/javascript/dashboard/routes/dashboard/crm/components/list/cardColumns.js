/**
 * Column-definition module for the CRM cards list (TanStack vue-table v8).
 *
 * Pure module — no Vue component imports, no store access. Consumers build the
 * column set via `buildCrmCardColumns({ t, stages, agents, density })` and pass
 * the result straight into `useVueTable`.
 *
 * Inline-edit cells are rendered by CrmCardsTable.vue using `column.meta.editField`
 * (it owns the editing state + delegates to the sibling `CrmTableCellEditable`
 * component). The column defs here only describe identity, accessor, header label,
 * sortability, default size and display-only formatting helpers.
 *
 * NOTE on timestamps: list payload sends ISO8601 strings while board/realtime use
 * epoch seconds. `toDate()` accepts BOTH (mirrors the existing followUpDate helper).
 */

// Column ids that the backend can sort on (server-side sort).
export const SORTABLE_COLUMN_IDS = [
  'value',
  'followUp',
  'lastActivity',
  'enteredStage',
  'title',
];

// Maps a TanStack column id -> backend `sort` param value.
export const COLUMN_TO_SORT_PARAM = {
  value: 'value_cents',
  followUp: 'next_follow_up_at',
  lastActivity: 'last_activity_at',
  enteredStage: 'entered_stage_at',
  title: 'title',
};

// Canonical left-to-right order (select is always pinned first via sticky).
export const DEFAULT_COLUMN_ORDER = [
  'select',
  'title',
  'stage',
  'owner',
  'responsible',
  'value',
  'status',
  'sla',
  'followUp',
  'lastActivity',
  'inbox',
  'priority',
  'conversation',
  'meta',
];

// Columns shown by default (false = hidden until user enables in settings menu).
export const DEFAULT_COLUMN_VISIBILITY = {
  select: true,
  title: true,
  stage: true,
  owner: true,
  responsible: false,
  value: true,
  status: true,
  followUp: true,
  lastActivity: false,
  inbox: true,
  priority: false,
  conversation: false,
  meta: true,
};

// Per-column default pixel widths (TanStack columnSizing seed).
const COLUMN_SIZES = {
  select: 44,
  title: 260,
  stage: 150,
  owner: 160,
  responsible: 160,
  value: 130,
  status: 120,
  sla: 110,
  followUp: 160,
  lastActivity: 150,
  inbox: 150,
  priority: 110,
  conversation: 140,
  meta: 120,
};

/**
 * Accepts an ISO8601 string OR epoch seconds OR epoch ms and returns a Date,
 * or null when empty/invalid.
 * @param {string|number|null|undefined} value
 * @returns {Date|null}
 */
export const toDate = value => {
  if (value === null || value === undefined || value === '') return null;
  if (typeof value === 'number') {
    // epoch seconds (board/realtime) vs ms — seconds are < 1e12.
    const ms = value < 1e12 ? value * 1000 : value;
    const d = new Date(ms);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  // numeric string from realtime payloads.
  if (/^\d+$/.test(value)) {
    return toDate(Number(value));
  }
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? null : d;
};

/**
 * Sortable accessor for date-ish fields: returns epoch ms (or 0 when absent)
 * so client-side fallback sorting on `cardsList` stays stable.
 */
const dateAccessor = field => row => {
  const d = toDate(row?.[field]);
  return d ? d.getTime() : 0;
};

/**
 * Builds the TanStack ColumnDef[] for the CRM cards list.
 *
 * @param {Object}   args
 * @param {Function} args.t        - vue-i18n translate fn.
 * @param {Array}    [args.stages] - pipeline stages (for stage cell editor options).
 * @param {Array}    [args.agents] - agents (for owner cell editor options).
 * @param {Boolean}  [args.includeMeta] - append the Meta conversion column (only
 *   relevant for accounts running Click-to-WhatsApp ads).
 * @returns {Array} TanStack ColumnDef[]
 */
export const buildCrmCardColumns = ({
  t,
  stages = [],
  agents = [],
  includeMeta = false,
} = {}) => {
  const L = key => t(`CRM_KANBAN.LIST.COLUMNS.${key}`);

  // Each non-select column carries meta describing how CrmCardsTable should render
  // it: `editable` (delegates to CrmTableCellEditable on click), `field` (backend
  // field), `frozen`, `align`, and `kind` (drives the read-only renderer).
  return [
    {
      id: 'select',
      enableSorting: false,
      enableHiding: false,
      enableResizing: false,
      size: COLUMN_SIZES.select,
      minSize: COLUMN_SIZES.select,
      meta: { kind: 'select', frozen: true, align: 'center' },
    },
    {
      id: 'title',
      accessorFn: row => row?.title || '',
      header: L('TITLE'),
      enableSorting: true,
      enableHiding: false,
      size: COLUMN_SIZES.title,
      minSize: 180,
      meta: {
        kind: 'title',
        frozen: true,
        sortParam: COLUMN_TO_SORT_PARAM.title,
      },
    },
    {
      id: 'stage',
      accessorFn: row => row?.stage_id,
      header: L('STAGE'),
      enableSorting: false,
      size: COLUMN_SIZES.stage,
      meta: {
        kind: 'stage',
        editable: true,
        field: 'stage',
        options: stages,
      },
    },
    {
      id: 'owner',
      accessorFn: row => row?.owner_id,
      header: L('OWNER'),
      enableSorting: false,
      size: COLUMN_SIZES.owner,
      meta: {
        kind: 'owner',
        editable: true,
        field: 'owner',
        options: agents,
      },
    },
    {
      id: 'responsible',
      accessorFn: row => row?.responsible?.name || '',
      header: L('RESPONSIBLE'),
      enableSorting: false,
      size: COLUMN_SIZES.responsible,
      meta: { kind: 'responsible' },
    },
    {
      id: 'value',
      accessorFn: row => Number(row?.value_cents || 0),
      header: L('VALUE'),
      enableSorting: true,
      size: COLUMN_SIZES.value,
      meta: {
        kind: 'value',
        editable: true,
        field: 'value',
        align: 'right',
        sortParam: COLUMN_TO_SORT_PARAM.value,
      },
    },
    {
      id: 'status',
      accessorFn: row => row?.status || 'open',
      header: L('STATUS'),
      enableSorting: false,
      size: COLUMN_SIZES.status,
      meta: { kind: 'status', editable: true, field: 'status' },
    },
    {
      id: 'sla',
      accessorFn: row => row?.conversation?.applied_sla?.id ?? '',
      header: L('SLA'),
      enableSorting: false,
      size: COLUMN_SIZES.sla,
      meta: { kind: 'sla' },
    },
    {
      id: 'followUp',
      accessorFn: dateAccessor('next_follow_up_at'),
      header: L('FOLLOW_UP'),
      enableSorting: true,
      size: COLUMN_SIZES.followUp,
      meta: {
        kind: 'followUp',
        editable: true,
        field: 'next_follow_up_at',
        sortParam: COLUMN_TO_SORT_PARAM.followUp,
      },
    },
    {
      id: 'lastActivity',
      accessorFn: dateAccessor('last_activity_at'),
      header: L('LAST_ACTIVITY'),
      enableSorting: true,
      size: COLUMN_SIZES.lastActivity,
      meta: {
        kind: 'lastActivity',
        sortParam: COLUMN_TO_SORT_PARAM.lastActivity,
      },
    },
    {
      id: 'inbox',
      accessorFn: row => row?.inbox?.name || '',
      header: L('INBOX'),
      enableSorting: false,
      size: COLUMN_SIZES.inbox,
      meta: { kind: 'inbox' },
    },
    {
      id: 'priority',
      accessorFn: row => row?.priority || '',
      header: L('PRIORITY'),
      enableSorting: false,
      size: COLUMN_SIZES.priority,
      meta: { kind: 'priority' },
    },
    {
      id: 'conversation',
      accessorFn: row => row?.conversation?.display_id,
      header: L('CONVERSATION'),
      enableSorting: false,
      size: COLUMN_SIZES.conversation,
      meta: { kind: 'conversation' },
    },
    ...(includeMeta
      ? [
          {
            id: 'meta',
            accessorFn: row => row?.meta_conversion?.status || '',
            header: L('META'),
            enableSorting: false,
            size: COLUMN_SIZES.meta,
            meta: { kind: 'meta' },
          },
        ]
      : []),
  ];
};

/**
 * pt-BR currency formatter for value_cents.
 * @param {number} cents
 * @param {string} [currency='BRL']
 * @param {string} fallback - text when there is no value.
 * @returns {string}
 */
export const formatMoneyCents = (cents, currency = 'BRL', fallback = '—') => {
  const amount = Number(cents || 0);
  if (!amount) return fallback;
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: currency || 'BRL',
  }).format(amount / 100);
};
