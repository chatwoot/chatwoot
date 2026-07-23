export const DATE_PRESETS = [
  { value: 'today', labelKey: 'REPORT_PANELS.DATE_PRESETS.TODAY' },
  { value: 'yesterday', labelKey: 'REPORT_PANELS.DATE_PRESETS.YESTERDAY' },
  { value: 'last_7_days', labelKey: 'REPORT_PANELS.DATE_PRESETS.LAST_7_DAYS' },
  {
    value: 'last_30_days',
    labelKey: 'REPORT_PANELS.DATE_PRESETS.LAST_30_DAYS',
  },
  { value: 'custom', labelKey: 'REPORT_PANELS.DATE_PRESETS.CUSTOM' },
];

export const METRIC_OPTIONS = [
  'conversations_count',
  'unique_contacts_count',
  'contacts_count',
  'incoming_messages_count',
  'outgoing_messages_count',
  'avg_first_response_time',
  'avg_resolution_time',
  'reply_time',
  'resolutions_count',
];

export const METRIC_SOURCES = [
  { value: 'preset', labelKey: 'REPORT_PANELS.METRIC_SOURCES.PRESET' },
  {
    value: 'aggregation',
    labelKey: 'REPORT_PANELS.METRIC_SOURCES.AGGREGATION',
  },
];

export const AGGREGATION_OPS = [
  { value: 'count', labelKey: 'REPORT_PANELS.AGGREGATIONS.COUNT' },
  { value: 'sum', labelKey: 'REPORT_PANELS.AGGREGATIONS.SUM' },
  { value: 'avg', labelKey: 'REPORT_PANELS.AGGREGATIONS.AVG' },
  { value: 'min', labelKey: 'REPORT_PANELS.AGGREGATIONS.MIN' },
  { value: 'max', labelKey: 'REPORT_PANELS.AGGREGATIONS.MAX' },
];

export const COLUMN_AGGREGATION_OPS = [
  { value: '', labelKey: 'REPORT_PANELS.AGGREGATIONS.NONE' },
  { value: 'sum', labelKey: 'REPORT_PANELS.AGGREGATIONS.SUM' },
  { value: 'avg', labelKey: 'REPORT_PANELS.AGGREGATIONS.AVG' },
  { value: 'count', labelKey: 'REPORT_PANELS.AGGREGATIONS.COUNT' },
  { value: 'min', labelKey: 'REPORT_PANELS.AGGREGATIONS.MIN' },
  { value: 'max', labelKey: 'REPORT_PANELS.AGGREGATIONS.MAX' },
];

export const AGGREGATION_ENTITIES = [
  {
    value: 'conversations',
    labelKey: 'REPORT_PANELS.AGGREGATION_ENTITIES.CONVERSATIONS',
  },
  {
    value: 'contacts',
    labelKey: 'REPORT_PANELS.AGGREGATION_ENTITIES.CONTACTS',
  },
];

export const TABLE_KINDS = [
  { value: 'agent_summary', labelKey: 'REPORT_PANELS.TABLE_KINDS.AGENT' },
  { value: 'inbox_summary', labelKey: 'REPORT_PANELS.TABLE_KINDS.INBOX' },
  { value: 'team_summary', labelKey: 'REPORT_PANELS.TABLE_KINDS.TEAM' },
  { value: 'label_summary', labelKey: 'REPORT_PANELS.TABLE_KINDS.LABEL' },
  {
    value: 'conversations',
    labelKey: 'REPORT_PANELS.TABLE_KINDS.CONVERSATIONS',
  },
  {
    value: 'contacts',
    labelKey: 'REPORT_PANELS.TABLE_KINDS.CONTACTS',
  },
];

export const TABLE_COLUMN_OPTIONS = {
  conversations: [
    'id',
    'contact_name',
    'status',
    'priority',
    'labels',
    'inbox',
    'assignee',
    'created_at',
    'last_activity_at',
  ],
  contacts: [
    'name',
    'phone_number',
    'email',
    'document_number',
    'labels',
    'conversations_count',
    'assignee',
    'inbox',
    'created_at',
    'last_activity_at',
    'id',
  ],
  agent_summary: [
    'rank',
    'name',
    'conversations_count',
    'resolved_conversations_count',
    'csat_avg',
    'incoming_messages_count',
    'outgoing_messages_count',
    'avg_first_response_time',
    'avg_resolution_time',
    'avg_reply_time',
    'share_percent',
  ],
  inbox_summary: [
    'rank',
    'name',
    'conversations_count',
    'resolved_conversations_count',
    'avg_first_response_time',
    'avg_resolution_time',
    'avg_reply_time',
    'share_percent',
  ],
  team_summary: [
    'rank',
    'name',
    'conversations_count',
    'resolved_conversations_count',
    'avg_first_response_time',
    'avg_resolution_time',
    'avg_reply_time',
    'share_percent',
  ],
  label_summary: [
    'rank',
    'name',
    'conversations_count',
    'resolved_conversations_count',
    'avg_first_response_time',
    'avg_resolution_time',
    'avg_reply_time',
    'share_percent',
  ],
};

export const DEFAULT_TABLE_COLUMNS = {
  conversations: [
    'id',
    'contact_name',
    'status',
    'assignee',
    'inbox',
    'created_at',
  ],
  contacts: [
    'name',
    'phone_number',
    'email',
    'assignee',
    'inbox',
    'conversations_count',
    'last_activity_at',
  ],
};

/** Prefix for custom-attribute columns stored in widget.columns */
export const CA_COLUMN_PREFIX = 'ca:';
/** Contact custom attrs on summary tables (agent/inbox/team/label) */
export const CONTACT_CA_COLUMN_PREFIX = 'contact_ca:';

export const SUMMARY_TABLE_KINDS = new Set([
  'agent_summary',
  'inbox_summary',
  'team_summary',
  'label_summary',
]);

export const isConversationCustomAttributeColumn = key =>
  typeof key === 'string' && key.startsWith(CA_COLUMN_PREFIX);

export const isContactCustomAttributeColumn = key =>
  typeof key === 'string' && key.startsWith(CONTACT_CA_COLUMN_PREFIX);

export const isCustomAttributeColumn = key =>
  isConversationCustomAttributeColumn(key) ||
  isContactCustomAttributeColumn(key);

export const customAttributeKeyFromColumn = key => {
  if (isContactCustomAttributeColumn(key)) {
    return key.slice(CONTACT_CA_COLUMN_PREFIX.length);
  }
  if (isConversationCustomAttributeColumn(key)) {
    return key.slice(CA_COLUMN_PREFIX.length);
  }
  return null;
};

export const customAttributeColumnKey = attributeKey =>
  `${CA_COLUMN_PREFIX}${attributeKey}`;

export const contactCustomAttributeColumnKey = attributeKey =>
  `${CONTACT_CA_COLUMN_PREFIX}${attributeKey}`;

/** Additive count columns eligible for footer aggregations */
export const SUMMABLE_SYSTEM_COLUMNS = new Set([
  'conversations_count',
  'resolved_conversations_count',
  'incoming_messages_count',
  'outgoing_messages_count',
]);

export const SUMMABLE_CUSTOM_TYPES = new Set(['number', 'currency', 'percent']);

/**
 * Parse number/currency/percent CA values that may use locale separators
 * ("1000,00", "1.000,50", "1,000.50") or currency symbols ("$10").
 * Returns null when the value cannot be interpreted as a finite number.
 */
export const parseLocaleNumber = value => {
  if (value == null || value === '') return null;
  if (typeof value === 'number') {
    return Number.isFinite(value) ? value : null;
  }

  let str = String(value)
    .trim()
    .replace(/[^\d,.-]/g, '');
  if (!str || str === '-' || str === '.' || str === ',') return null;

  if (str.includes(',') && str.includes('.')) {
    if (str.lastIndexOf(',') > str.lastIndexOf('.')) {
      // European: 1.000,50
      str = str.replace(/\./g, '').replace(',', '.');
    } else {
      // US: 1,000.50
      str = str.replace(/,/g, '');
    }
  } else if (str.includes(',')) {
    const parts = str.split(',');
    if (parts.length === 2 && parts[1].length >= 1 && parts[1].length <= 2) {
      // Decimal comma: 1000,00 / 10,5
      str = str.replace(',', '.');
    } else {
      // Thousands commas: 1,000 / 1,000,000
      str = str.replace(/,/g, '');
    }
  }

  const num = Number(str);
  return Number.isFinite(num) ? num : null;
};

/** Format numeric CA cells/footers; currency always shown with `$`. */
export const formatNumericAttribute = (value, type) => {
  const num = parseLocaleNumber(value);
  if (num == null) return value == null || value === '' ? '—' : String(value);

  if (type === 'currency') {
    return `$${num.toLocaleString(undefined, {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })}`;
  }
  if (type === 'percent') {
    return `${num.toLocaleString(undefined, {
      maximumFractionDigits: 2,
    })}%`;
  }
  return num.toLocaleString(undefined, { maximumFractionDigits: 2 });
};

export const isAggregatableColumn = (key, attributeTypes = {}) => {
  if (SUMMABLE_SYSTEM_COLUMNS.has(key)) return true;
  if (!isCustomAttributeColumn(key)) return false;
  const attrKey = customAttributeKeyFromColumn(key);
  return (
    SUMMABLE_CUSTOM_TYPES.has(attributeTypes[key]) ||
    SUMMABLE_CUSTOM_TYPES.has(attributeTypes[attrKey])
  );
};

export const defaultColumnsForTableKind = kind => {
  if (DEFAULT_TABLE_COLUMNS[kind]) return [...DEFAULT_TABLE_COLUMNS[kind]];
  if (TABLE_COLUMN_OPTIONS[kind]) return [...TABLE_COLUMN_OPTIONS[kind]];
  return [];
};

export const resolveTableColumns = (kind, columns) => {
  const systemAllowed = TABLE_COLUMN_OPTIONS[kind] || [];
  if (!systemAllowed.length) return [];
  const selected = Array.isArray(columns)
    ? columns.filter(
        key => systemAllowed.includes(key) || isCustomAttributeColumn(key)
      )
    : [];
  return selected.length ? selected : defaultColumnsForTableKind(kind);
};

/** Prefix for contact-entity filters (labels, etc.) routed to Contacts::FilterService */
export const CONTACT_FILTER_PREFIX = 'contact:';
export const CONTACT_ATTR_PREFIX = 'contact_ca:';

export const MULTI_SELECT_SYSTEM_KEYS = new Set(['assignee_id', 'inbox_id']);

export const newWidgetId = () =>
  `w_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

export const defaultMetricWidget = () => ({
  id: newWidgetId(),
  type: 'metric',
  title: '',
  source: 'preset',
  metric: 'conversations_count',
  aggregation_op: 'count',
  aggregation_field: '',
  aggregation_group_field: '',
  aggregation_entity: 'conversations',
  scope_type: 'account',
  scope_id: null,
});

export const defaultChartWidget = () => ({
  id: newWidgetId(),
  type: 'chart',
  title: '',
  source: 'preset',
  metric: 'conversations_count',
  aggregation_op: 'count',
  aggregation_field: '',
  aggregation_group_field: '',
  aggregation_entity: 'conversations',
  scope_type: 'account',
  scope_id: null,
  chart_kind: 'bar',
  group_by: 'day',
});

export const defaultTableWidget = () => ({
  id: newWidgetId(),
  type: 'table',
  title: '',
  table_kind: 'agent_summary',
  columns: [],
  column_aggregations: {},
});

export const emptyPanel = () => ({
  name: '',
  description: '',
  date_preset: 'last_7_days',
  custom_since: null,
  custom_until: null,
  business_hours: false,
  favorite: false,
  filters: [],
  widgets: [defaultMetricWidget(), defaultChartWidget()],
});

/** Map saved panel date_preset → WootDatePicker rangeType. */
export const panelPresetToRangeType = preset => {
  switch (preset) {
    case 'last_30_days':
      return 'last30days';
    case 'custom':
    case 'today':
    case 'yesterday':
      // Picker has no today/yesterday presets — show as custom with exact dates.
      return 'custom';
    case 'last_7_days':
    default:
      return 'last7days';
  }
};

/** Resolve panel saved range into Date objects for the picker. */
export const panelRangeToDates = panel => {
  const now = new Date();
  const startOfDay = d => {
    const date = new Date(d);
    date.setHours(0, 0, 0, 0);
    return date;
  };
  const endOfDay = d => {
    const date = new Date(d);
    date.setHours(23, 59, 59, 999);
    return date;
  };

  if (
    panel?.date_preset === 'custom' &&
    panel.custom_since &&
    panel.custom_until
  ) {
    return [
      new Date(panel.custom_since * 1000),
      new Date(panel.custom_until * 1000),
    ];
  }

  switch (panel?.date_preset) {
    case 'today':
      return [startOfDay(now), endOfDay(now)];
    case 'yesterday': {
      const day = new Date(now);
      day.setDate(day.getDate() - 1);
      return [startOfDay(day), endOfDay(day)];
    }
    case 'last_30_days': {
      const from = new Date(now);
      from.setDate(from.getDate() - 29);
      return [startOfDay(from), endOfDay(now)];
    }
    case 'last_7_days':
    default: {
      const from = new Date(now);
      from.setDate(from.getDate() - 6);
      return [startOfDay(from), endOfDay(now)];
    }
  }
};
