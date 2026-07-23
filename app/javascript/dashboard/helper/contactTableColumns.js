export const ALLOWED_CONTACTS_PER_PAGE = Object.freeze([15, 25, 50, 100]);
export const DEFAULT_CONTACTS_PER_PAGE = 15;

export const DEFAULT_CONTACT_TABLE_COLUMNS = Object.freeze([
  'name',
  'document_number',
  'phone_number',
  'email',
  'labels',
  'assigned_agent',
  'last_activity_at',
]);

/** Standard columns available in the contacts table / export UI */
export const STANDARD_CONTACT_COLUMNS = Object.freeze([
  {
    key: 'name',
    labelKey: 'NAME',
    sortable: true,
    sortKey: 'name',
    required: true,
    exportKey: 'name',
  },
  {
    key: 'document_number',
    labelKey: 'IDENTITY',
    sortable: true,
    sortKey: 'document_number',
    exportKey: 'document_number',
  },
  {
    key: 'phone_number',
    labelKey: 'PHONE',
    sortable: true,
    sortKey: 'phone_number',
    exportKey: 'phone_number',
  },
  {
    key: 'email',
    labelKey: 'EMAIL',
    sortable: true,
    sortKey: 'email',
    exportKey: 'email',
  },
  {
    key: 'identifier',
    labelKey: 'IDENTIFIER',
    sortable: true,
    sortKey: 'identifier',
    exportKey: 'identifier',
  },
  {
    key: 'company_name',
    labelKey: 'COMPANY',
    sortable: true,
    sortKey: 'company_name',
    exportKey: 'company_name',
  },
  {
    key: 'city',
    labelKey: 'CITY',
    sortable: true,
    sortKey: 'city',
    exportKey: 'city',
  },
  {
    key: 'country',
    labelKey: 'COUNTRY',
    sortable: true,
    sortKey: 'country',
    exportKey: 'country',
  },
  {
    key: 'labels',
    labelKey: 'LABELS',
    sortable: true,
    sortKey: 'labels',
    exportKey: 'labels',
  },
  {
    key: 'assigned_agent',
    labelKey: 'ASSIGNED_AGENT',
    sortable: true,
    sortKey: 'assigned_agent',
    exportKey: 'assigned_agent',
  },
  {
    key: 'created_at',
    labelKey: 'CREATED_AT',
    sortable: true,
    sortKey: 'created_at',
    exportKey: 'created_at',
  },
  {
    key: 'last_activity_at',
    labelKey: 'LAST_ACTIVITY',
    sortable: true,
    sortKey: 'last_activity_at',
    exportKey: 'last_activity_at',
  },
  {
    key: 'blocked',
    labelKey: 'BLOCKED',
    sortable: true,
    sortKey: 'blocked',
    exportKey: 'blocked',
  },
]);

export const customColumnKey = attributeKey => `custom:${attributeKey}`;

export const isCustomColumnKey = key =>
  typeof key === 'string' && key.startsWith('custom:');

export const attributeKeyFromColumn = key =>
  isCustomColumnKey(key) ? key.slice('custom:'.length) : null;

const SORTABLE_CUSTOM_DISPLAY_TYPES = new Set([
  'text',
  'number',
  'currency',
  'percent',
  'date',
  'datetime',
  'link',
]);

const DISPLAY_TYPE_ALIASES = {
  0: 'text',
  1: 'number',
  2: 'currency',
  3: 'percent',
  4: 'link',
  5: 'date',
  6: 'list',
  7: 'checkbox',
  8: 'datetime',
};

export const normalizeDisplayType = displayType => {
  if (displayType == null || displayType === '') return 'text';
  if (typeof displayType === 'number') {
    return DISPLAY_TYPE_ALIASES[displayType] || 'text';
  }
  const asString = String(displayType);
  // Numeric string enums from JSON ("2" â†’ currency)
  if (/^\d+$/.test(asString)) {
    return DISPLAY_TYPE_ALIASES[Number(asString)] || 'text';
  }
  return asString;
};

export const isNumericCustomDisplayType = displayType => {
  const type = normalizeDisplayType(displayType);
  return type === 'number' || type === 'currency' || type === 'percent';
};

export const buildCustomColumns = attributeDefinitions =>
  (attributeDefinitions || []).map(def => {
    const attributeKey = def.attribute_key || def.attributeKey;
    const displayType = normalizeDisplayType(
      def.attribute_display_type ?? def.attributeDisplayType
    );
    const hasFormula = !!(def.formula && (def.formula.op || def.formula.Op));
    return {
      key: customColumnKey(attributeKey),
      label: def.attribute_display_name || def.attributeDisplayName,
      attributeKey,
      displayType,
      formula: def.formula,
      featured: def.featured === true || def.featured === 1,
      // Formula results are numeric; keep column sortable even if display type is odd
      sortable: SORTABLE_CUSTOM_DISPLAY_TYPES.has(displayType) || hasFormula,
      sortKey: customColumnKey(attributeKey),
      exportKey: attributeKey,
      numeric: isNumericCustomDisplayType(displayType) || hasFormula,
    };
  });

/**
 * Build default visible columns from the standard set only (no Metrics / featured bundle).
 */
export const buildDefaultVisibleColumns = availableKeys => {
  const available = new Set(availableKeys);
  return DEFAULT_CONTACT_TABLE_COLUMNS.filter(key => available.has(key));
};

/**
 * Coerce ui_settings column prefs to a string[].
 * Rails strong params / jsonb edge cases can turn arrays into {"0":"name",...}.
 */
export const normalizeSavedColumnKeys = savedKeys => {
  if (Array.isArray(savedKeys)) {
    return savedKeys.filter(key => typeof key === 'string' && key.length);
  }
  if (savedKeys && typeof savedKeys === 'object') {
    return Object.keys(savedKeys)
      .filter(k => /^\d+$/.test(k))
      .sort((a, b) => Number(a) - Number(b))
      .map(k => savedKeys[k])
      .filter(key => typeof key === 'string' && key.length);
  }
  return [];
};

export const resolveVisibleColumns = (savedKeys, availableKeys) => {
  const available = new Set(availableKeys);
  const defaults = buildDefaultVisibleColumns(availableKeys);

  // Migrate away from legacy "featured" / Metrics column
  const cleaned = normalizeSavedColumnKeys(savedKeys).filter(
    key => key !== 'featured' && available.has(key)
  );

  if (!cleaned.length) return defaults;

  // Keep name pinned first without otherwise reshuffling custom order
  const withoutName = cleaned.filter(key => key !== 'name');
  if (available.has('name')) {
    return ['name', ...withoutName];
  }
  return withoutName;
};

export const normalizeContactsPerPage = value => {
  const n = Number(value);
  return ALLOWED_CONTACTS_PER_PAGE.includes(n) ? n : DEFAULT_CONTACTS_PER_PAGE;
};

/** Map visible table columns to export header keys. */
export const tableColumnsToExportKeys = (
  visibleKeys,
  { includeId = true } = {}
) => {
  const byKey = Object.fromEntries(
    STANDARD_CONTACT_COLUMNS.map(col => [col.key, col])
  );
  const keys = [];
  if (includeId) keys.push('id');

  visibleKeys.forEach(key => {
    if (key === 'featured') return;
    if (isCustomColumnKey(key)) {
      keys.push(attributeKeyFromColumn(key));
      return;
    }
    const exportKey = byKey[key]?.exportKey;
    if (exportKey) keys.push(exportKey);
  });

  return [...new Set(keys.filter(Boolean))];
};
