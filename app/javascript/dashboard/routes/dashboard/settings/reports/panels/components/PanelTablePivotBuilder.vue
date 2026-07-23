<script setup>
/**
 * Excel-style pivot / tabla dinámica builder for report panel tables.
 * Summary: Campos → Filas / Columnas / Valores (drag or add).
 * Detail: searchable grouped column picker.
 */
/* eslint-disable vue/no-mutating-props -- widget is a mutable panel form draft from Edit.vue */
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Draggable from 'vuedraggable';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import SelectInput from 'dashboard/components-next/select/Select.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  SUMMARY_TABLE_KINDS,
  PIVOT_COLUMN_ATTR_TYPES,
  PIVOT_IDENTITY_COLUMNS,
  MAX_PIVOT_VALUES,
  SUMMABLE_SYSTEM_COLUMNS,
  SUMMABLE_CUSTOM_TYPES,
  TABLE_COLUMN_OPTIONS,
  MEASURE_OPS,
  defaultPivotConfig,
  defaultColumnsForTableKind,
  customAttributeColumnKey,
  contactCustomAttributeColumnKey,
  customAttributeMeasureColumnKey,
  measureOpFromColumn,
  isCustomAttributeColumn,
  parseCustomAttributeColumn,
  summaryMeasureOpsForAttrType,
  summaryIdentityColumnsFor,
  summarySystemMeasureKeysFor,
  normalizeAttrDisplayType,
} from '../panelConstants';

const props = defineProps({
  widget: { type: Object, required: true },
  tableKindOptions: { type: Array, default: () => [] },
  conversationAttributes: { type: Array, default: () => [] },
  contactAttributes: { type: Array, default: () => [] },
});

const emit = defineEmits(['tableKindChange']);

const { t } = useI18n();
const fieldSearch = ref('');
const detailSearch = ref('');
const addMeasureFieldId = ref('');
const addMeasureOp = ref('count');
const dragging = ref(false);

const isSummary = computed(() =>
  SUMMARY_TABLE_KINDS.has(props.widget.table_kind)
);

const ensurePivot = () => {
  if (!props.widget.pivot) props.widget.pivot = defaultPivotConfig();
  return props.widget.pivot;
};

const selectedColumns = computed(() => {
  if (Array.isArray(props.widget.columns) && props.widget.columns.length) {
    return [...props.widget.columns];
  }
  return defaultColumnsForTableKind(props.widget.table_kind);
});

const aggregationOpOptions = computed(() =>
  MEASURE_OPS.map(op => ({
    value: op,
    label: t(`REPORT_PANELS.AGGREGATIONS.${op.toUpperCase()}`),
  }))
);

const footerAggregationOptions = computed(() => [
  { value: '', label: t('REPORT_PANELS.AGGREGATIONS.NONE') },
  ...aggregationOpOptions.value,
]);

/** Catalog: each attribute / system metric once. */
const fieldCatalog = computed(() => {
  const kind = props.widget.table_kind;
  const fields = [];

  summarySystemMeasureKeysFor(kind).forEach(key => {
    fields.push({
      id: `sys:${key}`,
      group: 'system',
      kind: 'system',
      label: t(`REPORT_PANELS.COLUMNS.${key}`),
      columnBase: key,
      attrType: '',
      canPivot: false,
      measureOps: [],
      contact: false,
    });
  });

  (props.conversationAttributes || []).forEach(attr => {
    const attributeKey = attr.attributeKey || attr.attribute_key;
    if (!attributeKey) return;
    const attrType = normalizeAttrDisplayType(attr);
    const name =
      attr.attributeDisplayName || attr.attribute_display_name || attributeKey;
    fields.push({
      id: `ca:${attributeKey}`,
      group: 'conversation',
      kind: 'conversation_ca',
      label: name,
      columnBase: customAttributeColumnKey(attributeKey),
      attributeKey,
      attrType,
      canPivot: PIVOT_COLUMN_ATTR_TYPES.has(attrType),
      measureOps: summaryMeasureOpsForAttrType(attrType),
      contact: false,
      attributeValues: attr.attributeValues || attr.attribute_values || [],
    });
  });

  (props.contactAttributes || []).forEach(attr => {
    const attributeKey = attr.attributeKey || attr.attribute_key;
    if (!attributeKey) return;
    const attrType = normalizeAttrDisplayType(attr);
    const name =
      attr.attributeDisplayName || attr.attribute_display_name || attributeKey;
    fields.push({
      id: `contact_ca:${attributeKey}`,
      group: 'contact',
      kind: 'contact_ca',
      label: t('REPORT_PANELS.COLUMNS.CONTACT_CA_PREFIX', { name }),
      columnBase: contactCustomAttributeColumnKey(attributeKey),
      attributeKey,
      attrType,
      canPivot: false,
      measureOps: summaryMeasureOpsForAttrType(attrType),
      contact: true,
      attributeValues: attr.attributeValues || attr.attribute_values || [],
    });
  });

  return fields;
});

const fieldById = computed(() =>
  Object.fromEntries(fieldCatalog.value.map(f => [f.id, f]))
);

const fieldByColumnBase = computed(() =>
  Object.fromEntries(fieldCatalog.value.map(f => [f.columnBase, f]))
);

const filterText = computed(() => fieldSearch.value.trim().toLowerCase());

const filteredFieldGroups = computed(() => {
  const q = filterText.value;
  const match = f => !q || f.label.toLowerCase().includes(q);
  const groups = [
    {
      key: 'system',
      label: t('REPORT_PANELS.PIVOT.FIELDS_SYSTEM'),
      items: fieldCatalog.value.filter(f => f.group === 'system' && match(f)),
    },
    {
      key: 'conversation',
      label: t('REPORT_PANELS.PIVOT.FIELDS_CONVERSATION'),
      items: fieldCatalog.value.filter(
        f => f.group === 'conversation' && match(f)
      ),
    },
    {
      key: 'contact',
      label: t('REPORT_PANELS.PIVOT.FIELDS_CONTACT'),
      items: fieldCatalog.value.filter(f => f.group === 'contact' && match(f)),
    },
  ];
  return groups.filter(g => g.items.length);
});

/** Exact measure keys already in Valores (`ca:ventas__count`, `conversations_count`, …). */
const usedMeasureColumnKeys = computed(() => {
  const keys = new Set();
  selectedColumns.value.forEach(key => {
    if (PIVOT_IDENTITY_COLUMNS.has(key)) return;
    keys.add(key);
  });
  return keys;
});

const measureColumnKeyFor = (field, op) => {
  if (!field) return null;
  if (field.kind === 'system') return field.columnBase;
  return customAttributeMeasureColumnKey(field.attributeKey, op, {
    contact: field.contact,
  });
};

const availableOpsForField = field => {
  if (!field) return [];
  const used = usedMeasureColumnKeys.value;
  if (field.kind === 'system') {
    return used.has(field.columnBase) ? [] : ['_sys'];
  }
  return (field.measureOps || []).filter(
    op => !used.has(measureColumnKeyFor(field, op))
  );
};

/** True when every available measure for this field is already in Valores. */
const isFieldFullyInValues = field => availableOpsForField(field).length === 0;

const nextFreeOpForField = field => {
  const available = availableOpsForField(field);
  if (!available.length || field?.kind === 'system') return null;
  if (available.includes('sum')) return 'sum';
  return available[0];
};

const isFieldInColumns = field => {
  const pivot = ensurePivot();
  return Boolean(field.canPivot && pivot.column_attribute === field.columnBase);
};

const MAX_SUGGESTIONS = 5;
const FEW_OPTION_MAX = 8;

const pivotCandidateScore = field => {
  if (!field?.canPivot || field.group !== 'conversation') return 0;
  const vals = Array.isArray(field.attributeValues)
    ? field.attributeValues.filter(Boolean)
    : [];
  let score = field.attrType === 'list' ? 100 : 40;
  if (vals.length > 0 && vals.length <= FEW_OPTION_MAX) {
    score += 50 - vals.length;
  } else if (vals.length > FEW_OPTION_MAX) {
    score += 10;
  } else if (field.attrType === 'text') {
    score += 15;
  }
  return score;
};

const countCandidateScore = field => {
  if (!field || field.kind === 'system') return 0;
  let score = 5;
  if (field.attrType === 'list') score = 40;
  else if (field.attrType === 'text') score = 25;
  else if (SUMMABLE_CUSTOM_TYPES.has(field.attrType)) score = 8;
  const vals = Array.isArray(field.attributeValues)
    ? field.attributeValues.filter(Boolean)
    : [];
  if (vals.length > 0 && vals.length <= FEW_OPTION_MAX) score += 15;
  if (field.group === 'conversation') score += 5;
  return score;
};

/** Ranked one-click chips — hide already applied measure keys; max ~5. */
const suggestions = computed(() => {
  if (!isSummary.value) return [];
  const items = [];
  const used = usedMeasureColumnKeys.value;
  const hasPivot = Boolean(ensurePivot().column_attribute);
  const suggestedMeasureKeys = new Set();

  if (!hasPivot) {
    const best = fieldCatalog.value
      .map(field => ({ field, score: pivotCandidateScore(field) }))
      .filter(item => item.score > 0)
      .sort((a, b) => b.score - a.score)[0];
    if (best) {
      items.push({
        id: `col:${best.field.id}`,
        kind: 'column',
        field: best.field,
        label: t('REPORT_PANELS.PIVOT.SUGGESTIONS.USE_IN_COLUMNS', {
          name: best.field.label,
        }),
      });
    }
  }

  const summable = fieldCatalog.value
    .filter(field => {
      if (field.kind === 'system') return false;
      if (!SUMMABLE_CUSTOM_TYPES.has(field.attrType)) return false;
      const sumKey = measureColumnKeyFor(field, 'sum');
      return sumKey && !used.has(sumKey);
    })
    .sort((a, b) => {
      const rank = type => {
        if (type === 'currency') return 3;
        if (type === 'number') return 2;
        return 1;
      };
      return rank(b.attrType) - rank(a.attrType);
    });

  summable.slice(0, 2).forEach(field => {
    if (items.length >= MAX_SUGGESTIONS) return;
    const sumKey = measureColumnKeyFor(field, 'sum');
    suggestedMeasureKeys.add(sumKey);
    items.push({
      id: `sum:${field.id}`,
      field,
      op: 'sum',
      kind: 'measure',
      label: t('REPORT_PANELS.PIVOT.SUGGESTIONS.ADD_SUM', {
        name: field.label,
      }),
    });
  });

  const countCandidates = fieldCatalog.value
    .filter(field => {
      if (field.kind === 'system') return false;
      const countKey = measureColumnKeyFor(field, 'count');
      return (
        countKey && !used.has(countKey) && !suggestedMeasureKeys.has(countKey)
      );
    })
    .map(field => ({ field, score: countCandidateScore(field) }))
    .filter(item => item.score > 0)
    .sort((a, b) => b.score - a.score);

  countCandidates.slice(0, 2).forEach(({ field }) => {
    if (items.length >= MAX_SUGGESTIONS) return;
    suggestedMeasureKeys.add(measureColumnKeyFor(field, 'count'));
    items.push({
      id: `count:${field.id}`,
      field,
      op: 'count',
      kind: 'measure',
      label: t('REPORT_PANELS.PIVOT.SUGGESTIONS.ADD_COUNT', {
        name: field.label,
      }),
    });
  });

  const systemChips = [
    {
      key: 'conversations_count',
      labelKey: 'REPORT_PANELS.PIVOT.SUGGESTIONS.ADD_SYSTEM_CONVERSATIONS',
    },
    {
      key: 'resolved_conversations_count',
      labelKey: 'REPORT_PANELS.PIVOT.SUGGESTIONS.ADD_SYSTEM_RESOLVED',
    },
  ];

  systemChips.forEach(({ key, labelKey }) => {
    if (items.length >= MAX_SUGGESTIONS) return;
    if (used.has(key)) return;
    const field = fieldByColumnBase.value[key];
    if (!field) return;
    items.push({
      id: `sys:${key}`,
      kind: 'system',
      field,
      label: t(labelKey),
    });
  });

  return items.slice(0, MAX_SUGGESTIONS);
});

const rowsLabel = computed(() => {
  const opt = props.tableKindOptions.find(
    item => item.value === props.widget.table_kind
  );
  return opt?.label || props.widget.table_kind;
});

const pivotField = computed(() => {
  const key = ensurePivot().column_attribute;
  if (!key) return null;
  return fieldByColumnBase.value[key] || null;
});

const pivotValueOptions = computed(() => {
  const field = pivotField.value;
  const values = field?.attributeValues || [];
  return Array.isArray(values)
    ? values.filter(Boolean).slice(0, MAX_PIVOT_VALUES)
    : [];
});

const pivotAttributeSelectOptions = computed(() => [
  { value: '', label: t('REPORT_PANELS.PIVOT.NONE') },
  ...fieldCatalog.value
    .filter(f => f.canPivot)
    .map(f => ({ value: f.columnBase, label: f.label })),
]);

const measureRows = computed(() => {
  return selectedColumns.value
    .filter(key => !PIVOT_IDENTITY_COLUMNS.has(key))
    .map(key => {
      if (isCustomAttributeColumn(key)) {
        const parsed = parseCustomAttributeColumn(key);
        const base = parsed.contact
          ? contactCustomAttributeColumnKey(parsed.attrKey)
          : customAttributeColumnKey(parsed.attrKey);
        const field = fieldByColumnBase.value[base];
        const op = parsed.op || 'count';
        return {
          columnKey: key,
          fieldId:
            field?.id ||
            (parsed.contact
              ? `contact_ca:${parsed.attrKey}`
              : `ca:${parsed.attrKey}`),
          label: field?.label || parsed.attrKey || key,
          op,
          isCustom: true,
          measureOps: field?.measureOps?.length
            ? field.measureOps
            : summaryMeasureOpsForAttrType(field?.attrType || ''),
          attrType: field?.attrType || '',
        };
      }
      return {
        columnKey: key,
        fieldId: `sys:${key}`,
        label: t(`REPORT_PANELS.COLUMNS.${key}`),
        op: null,
        isCustom: false,
        measureOps: [],
        attrType: '',
      };
    });
});

/** Local list for valores reorder (plain ref — vuedraggable). */
const valoresList = ref([]);

watch(
  measureRows,
  rows => {
    valoresList.value = rows.map(r => ({ ...r }));
  },
  { immediate: true, deep: true }
);

const syncColumnsFromMeasures = measures => {
  const identity = summaryIdentityColumnsFor(props.widget.table_kind);
  const measureKeys = measures.map(m => m.columnKey);
  props.widget.columns = [...identity, ...measureKeys];
};

const defaultOpForField = field => {
  if (!field?.measureOps?.length) return null;
  if (field.measureOps.includes('sum')) return 'sum';
  return field.measureOps[0];
};

const defaultFooterOp = (columnKey, op) => {
  if (!op || op === 'count' || op === 'sum') return 'sum';
  return op;
};

const setFooterAggregation = (columnKey, op, attrType = '') => {
  if (!props.widget.column_aggregations) {
    props.widget.column_aggregations = {};
  }
  const next = { ...props.widget.column_aggregations };
  const aggregatable =
    SUMMABLE_SYSTEM_COLUMNS.has(columnKey) ||
    SUMMABLE_CUSTOM_TYPES.has(attrType) ||
    Boolean(measureOpFromColumn(columnKey));
  if (!aggregatable || !op) {
    delete next[columnKey];
  } else {
    next[columnKey] = op;
  }
  props.widget.column_aggregations = next;
};

const addFieldToValues = field => {
  if (!field) return;
  if (field.kind === 'system') {
    if (usedMeasureColumnKeys.value.has(field.columnBase)) return;
    const measures = [
      ...valoresList.value,
      {
        columnKey: field.columnBase,
        fieldId: field.id,
        label: field.label,
        op: null,
        isCustom: false,
        measureOps: [],
        attrType: '',
      },
    ];
    valoresList.value = measures;
    syncColumnsFromMeasures(measures);
    if (SUMMABLE_SYSTEM_COLUMNS.has(field.columnBase)) {
      setFooterAggregation(field.columnBase, 'sum');
    }
    return;
  }
  const op = nextFreeOpForField(field);
  if (!op) return;
  const columnKey = measureColumnKeyFor(field, op);
  if (usedMeasureColumnKeys.value.has(columnKey)) return;
  const measures = [
    ...valoresList.value,
    {
      columnKey,
      fieldId: field.id,
      label: field.label,
      op,
      isCustom: true,
      measureOps: field.measureOps || [],
      attrType: field.attrType || '',
    },
  ];
  valoresList.value = measures;
  syncColumnsFromMeasures(measures);
  setFooterAggregation(
    columnKey,
    defaultFooterOp(columnKey, op),
    field.attrType
  );
};

const removeMeasure = columnKey => {
  const measures = valoresList.value.filter(m => m.columnKey !== columnKey);
  valoresList.value = measures;
  syncColumnsFromMeasures(measures);
  if (props.widget.column_aggregations?.[columnKey] != null) {
    const next = { ...props.widget.column_aggregations };
    delete next[columnKey];
    props.widget.column_aggregations = next;
  }
};

const changeMeasureOp = (row, op) => {
  if (!row.isCustom || !op) return;
  const field = fieldById.value[row.fieldId];
  if (!field) return;
  const oldKey = row.columnKey;
  const newKey = customAttributeMeasureColumnKey(field.attributeKey, op, {
    contact: field.contact,
  });
  if (newKey === oldKey) return;
  // Another Valores row already owns this measure key — don't clobber.
  if (valoresList.value.some(m => m.columnKey === newKey)) return;
  const measures = valoresList.value.map(m =>
    m.columnKey === oldKey ? { ...m, columnKey: newKey, op } : m
  );
  valoresList.value = measures;
  syncColumnsFromMeasures(measures);
  if (props.widget.column_aggregations?.[oldKey] != null) {
    const next = { ...props.widget.column_aggregations };
    delete next[oldKey];
    props.widget.column_aggregations = next;
  }
  setFooterAggregation(newKey, defaultFooterOp(newKey, op), field.attrType);
};

const onValoresReorder = () => {
  syncColumnsFromMeasures(valoresList.value);
};

const setPivotFromField = field => {
  const pivot = ensurePivot();
  if (!field || !field.canPivot) {
    pivot.column_attribute = '';
    pivot.column_values = [];
    return;
  }
  if (pivot.column_attribute === field.columnBase) return;
  pivot.column_attribute = field.columnBase;
  pivot.column_values = [];
};

const addMeasureWithOp = (field, op) => {
  if (!field) return;
  if (field.kind === 'system') {
    addFieldToValues(field);
    return;
  }
  const measureOp = op || nextFreeOpForField(field) || 'count';
  const columnKey = customAttributeMeasureColumnKey(
    field.attributeKey,
    measureOp,
    { contact: field.contact }
  );
  if (usedMeasureColumnKeys.value.has(columnKey)) return;
  const measures = [
    ...valoresList.value,
    {
      columnKey,
      fieldId: field.id,
      label: field.label,
      op: measureOp,
      isCustom: true,
      measureOps: field.measureOps || [],
      attrType: field.attrType || '',
    },
  ];
  valoresList.value = measures;
  syncColumnsFromMeasures(measures);
  setFooterAggregation(
    columnKey,
    defaultFooterOp(columnKey, measureOp),
    field.attrType
  );
};

const applySuggestion = suggestion => {
  if (!suggestion?.field) return;
  if (suggestion.kind === 'column') {
    setPivotFromField(suggestion.field);
    return;
  }
  if (suggestion.kind === 'system') {
    addFieldToValues(suggestion.field);
    return;
  }
  addMeasureWithOp(suggestion.field, suggestion.op);
};

const setPivotAttribute = attributeKey => {
  const pivot = ensurePivot();
  pivot.column_attribute = attributeKey || '';
  pivot.column_values = [];
};

const clearPivot = () => {
  const pivot = ensurePivot();
  pivot.column_attribute = '';
  pivot.column_values = [];
};

const isPivotValueSelected = value => {
  const selected = ensurePivot().column_values;
  if (!Array.isArray(selected) || !selected.length) return true;
  return selected.includes(value);
};

const togglePivotValue = value => {
  const pivot = ensurePivot();
  const all = pivotValueOptions.value;
  let selected = Array.isArray(pivot.column_values)
    ? [...pivot.column_values]
    : [];
  if (!selected.length) {
    selected = all.filter(item => item !== value);
  } else if (selected.includes(value)) {
    selected = selected.filter(item => item !== value);
  } else {
    selected.push(value);
  }
  pivot.column_values =
    selected.length === all.length ? [] : selected.slice(0, MAX_PIVOT_VALUES);
};

const onTableKindChange = kind => {
  emit('tableKindChange', kind);
};

const measureOpOptionsFor = row =>
  (row.measureOps?.length ? row.measureOps : MEASURE_OPS).map(op => ({
    value: op,
    label: t(`REPORT_PANELS.AGGREGATIONS.${op.toUpperCase()}`),
  }));

const addMeasureFieldOptions = computed(() => {
  return [
    { value: '', label: t('REPORT_PANELS.PIVOT.ADD_MEASURE_PLACEHOLDER') },
    ...fieldCatalog.value
      .filter(f => availableOpsForField(f).length > 0)
      .map(f => ({ value: f.id, label: f.label })),
  ];
});

const addMeasureOpOptions = computed(() => {
  const field = fieldById.value[addMeasureFieldId.value];
  if (!field || field.kind === 'system') {
    return [{ value: '', label: '—' }];
  }
  const available = availableOpsForField(field);
  return available.map(op => ({
    value: op,
    label: t(`REPORT_PANELS.AGGREGATIONS.${op.toUpperCase()}`),
  }));
});

watch(addMeasureFieldId, id => {
  const field = fieldById.value[id];
  addMeasureOp.value = field
    ? nextFreeOpForField(field) || defaultOpForField(field) || 'count'
    : 'count';
});

const confirmAddMeasure = () => {
  const field = fieldById.value[addMeasureFieldId.value];
  if (!field) return;
  if (field.kind === 'system') {
    addFieldToValues(field);
  } else {
    const op =
      addMeasureOp.value ||
      nextFreeOpForField(field) ||
      defaultOpForField(field);
    const columnKey = customAttributeMeasureColumnKey(field.attributeKey, op, {
      contact: field.contact,
    });
    if (usedMeasureColumnKeys.value.has(columnKey)) return;
    const measures = [
      ...valoresList.value,
      {
        columnKey,
        fieldId: field.id,
        label: field.label,
        op,
        isCustom: true,
        measureOps: field.measureOps || [],
        attrType: field.attrType || '',
      },
    ];
    valoresList.value = measures;
    syncColumnsFromMeasures(measures);
    setFooterAggregation(
      columnKey,
      defaultFooterOp(columnKey, op),
      field.attrType
    );
  }
  addMeasureFieldId.value = '';
};

/** Drop handlers: clone from Campos into zone. */
const columnasDropList = ref([]);

watch(pivotField, field => {
  columnasDropList.value = field ? [{ ...field }] : [];
});

const onColumnasChange = () => {
  const field = columnasDropList.value[0];
  if (!field) {
    clearPivot();
    return;
  }
  if (!field.canPivot) {
    columnasDropList.value = pivotField.value ? [{ ...pivotField.value }] : [];
    return;
  }
  // Keep only one pivot field
  if (columnasDropList.value.length > 1) {
    columnasDropList.value = [field];
  }
  setPivotFromField(field);
};

const onValoresAdd = evt => {
  const added = valoresList.value[evt.newIndex];
  // Catalog field cloned in — convert to measure row shape
  if (added?.columnBase && added?.id) {
    const field = fieldById.value[added.id] || added;
    valoresList.value.splice(evt.newIndex, 1);
    addFieldToValues(field);
  }
};

const footerAggValue = columnKey =>
  props.widget.column_aggregations?.[columnKey] || '';

const setFooterAgg = (columnKey, op) => {
  setFooterAggregation(columnKey, op || null);
};

const showFooterAgg = row => {
  if (row.isCustom) return false;
  return SUMMABLE_SYSTEM_COLUMNS.has(row.columnKey);
};

// —— Detail tables (conversations / contacts) ——

const detailColumnDefs = computed(() => {
  const kind = props.widget.table_kind;
  const system = (TABLE_COLUMN_OPTIONS[kind] || []).map(key => ({
    key,
    label: t(`REPORT_PANELS.COLUMNS.${key}`),
    group: 'system',
  }));
  if (kind === 'conversations') {
    const custom = (props.conversationAttributes || []).map(attr => {
      const attributeKey = attr.attributeKey || attr.attribute_key;
      const name =
        attr.attributeDisplayName ||
        attr.attribute_display_name ||
        attributeKey;
      return {
        key: customAttributeColumnKey(attributeKey),
        label: name,
        group: 'conversation',
      };
    });
    return [...system, ...custom];
  }
  if (kind === 'contacts') {
    const custom = (props.contactAttributes || []).map(attr => {
      const attributeKey = attr.attributeKey || attr.attribute_key;
      const name =
        attr.attributeDisplayName ||
        attr.attribute_display_name ||
        attributeKey;
      return {
        key: customAttributeColumnKey(attributeKey),
        label: name,
        group: 'contact',
      };
    });
    return [...system, ...custom];
  }
  return system;
});

const detailFilter = computed(() => detailSearch.value.trim().toLowerCase());

const detailGroups = computed(() => {
  const q = detailFilter.value;
  const match = item => !q || item.label.toLowerCase().includes(q);
  const groups = [
    {
      key: 'system',
      label: t('REPORT_PANELS.PIVOT.FIELDS_SYSTEM'),
      items: detailColumnDefs.value.filter(
        i => i.group === 'system' && match(i)
      ),
    },
    {
      key: 'conversation',
      label: t('REPORT_PANELS.PIVOT.FIELDS_CONVERSATION'),
      items: detailColumnDefs.value.filter(
        i => i.group === 'conversation' && match(i)
      ),
    },
    {
      key: 'contact',
      label: t('REPORT_PANELS.PIVOT.FIELDS_CONTACT'),
      items: detailColumnDefs.value.filter(
        i => i.group === 'contact' && match(i)
      ),
    },
  ];
  return groups.filter(g => g.items.length);
});

const isDetailSelected = key => selectedColumns.value.includes(key);

const toggleDetailColumn = key => {
  let cols = selectedColumns.value;
  if (cols.includes(key)) {
    cols = cols.filter(item => item !== key);
  } else {
    cols = [...cols, key];
  }
  const allowed = new Set(detailColumnDefs.value.map(i => i.key));
  props.widget.columns = cols.filter(
    item => allowed.has(item) || isCustomAttributeColumn(item)
  );
  if (!props.widget.columns.length) {
    props.widget.columns = defaultColumnsForTableKind(props.widget.table_kind);
  }
};
</script>

<template>
  <div class="flex flex-col gap-3">
    <!-- Table kind / Filas selector (always) -->
    <label class="text-sm text-n-slate-12 flex flex-col gap-1.5">
      {{ t('REPORT_PANELS.PIVOT.ROWS') }}
      <SelectInput
        :model-value="widget.table_kind"
        :options="tableKindOptions"
        full-width
        @update:model-value="onTableKindChange"
      />
      <span class="text-xs text-n-slate-11">
        {{ t('REPORT_PANELS.PIVOT.ROWS_HINT') }}
      </span>
    </label>

    <!-- Summary: Excel pivot builder -->
    <div
      v-if="isSummary"
      class="rounded-lg border border-n-weak overflow-hidden"
    >
      <div
        v-if="suggestions.length"
        class="px-3 py-2 border-b border-n-weak flex flex-col gap-1.5 bg-n-solid-1"
      >
        <span
          class="text-xs font-semibold uppercase tracking-wide text-n-slate-11"
        >
          {{ t('REPORT_PANELS.PIVOT.SUGGESTIONS.TITLE') }}
        </span>
        <div class="flex flex-wrap gap-1.5">
          <button
            v-for="item in suggestions"
            :key="item.id"
            type="button"
            class="inline-flex items-center gap-1 rounded-md border border-n-weak bg-n-background px-2 py-1 text-xs text-n-slate-12 hover:bg-n-brand/10 hover:border-n-brand"
            @click="applySuggestion(item)"
          >
            <Icon
              icon="i-lucide-sparkles"
              class="size-3 shrink-0 text-n-slate-11"
            />
            {{ item.label }}
          </button>
        </div>
      </div>
      <div
        class="grid grid-cols-1 lg:grid-cols-[minmax(14rem,18rem)_1fr] divide-y lg:divide-y-0 lg:divide-x divide-n-weak"
      >
        <!-- Campos -->
        <div class="flex flex-col min-h-[18rem] max-h-[28rem] bg-n-background">
          <div class="px-3 py-2 border-b border-n-weak flex flex-col gap-2">
            <span
              class="text-xs font-semibold uppercase tracking-wide text-n-slate-11"
            >
              {{ t('REPORT_PANELS.PIVOT.FIELDS') }}
            </span>
            <Input
              v-model="fieldSearch"
              :placeholder="t('REPORT_PANELS.PIVOT.FIELDS_SEARCH')"
              size="sm"
            />
          </div>
          <div class="flex-1 overflow-y-auto px-2 py-2">
            <p
              v-if="!filteredFieldGroups.length"
              class="text-xs text-n-slate-11 px-1 py-2"
            >
              {{ t('REPORT_PANELS.PIVOT.FIELDS_EMPTY') }}
            </p>
            <div
              v-for="group in filteredFieldGroups"
              :key="group.key"
              class="mb-3"
            >
              <div
                class="px-1 py-1 text-[11px] font-medium uppercase tracking-wide text-n-slate-10"
              >
                {{ group.label }}
              </div>
              <Draggable
                :list="group.items"
                :group="{ name: 'pivot-campos', pull: 'clone', put: false }"
                item-key="id"
                :clone="item => ({ ...item })"
                :sort="false"
                class="flex flex-col gap-0.5"
                @start="dragging = true"
                @end="dragging = false"
              >
                <template #item="{ element: field }">
                  <div
                    class="group flex items-center gap-1 rounded-md px-1.5 py-1 text-sm text-n-slate-12 hover:bg-n-alpha-2 cursor-grab active:cursor-grabbing"
                    :class="{
                      'opacity-50':
                        isFieldFullyInValues(field) && isFieldInColumns(field),
                    }"
                  >
                    <Icon
                      icon="i-woot-drag-indicator"
                      class="size-3.5 shrink-0 text-n-slate-10"
                    />
                    <span class="flex-1 truncate min-w-0" :title="field.label">
                      {{ field.label }}
                    </span>
                    <button
                      v-if="field.canPivot"
                      type="button"
                      class="shrink-0 text-[10px] px-1 py-0.5 rounded text-n-slate-11 hover:bg-n-alpha-2 opacity-0 group-hover:opacity-100"
                      :title="t('REPORT_PANELS.PIVOT.ADD_TO_COLUMNS')"
                      @click.stop="setPivotFromField(field)"
                    >
                      {{ t('REPORT_PANELS.PIVOT.ZONE_COLUMNS_SHORT') }}
                    </button>
                    <button
                      type="button"
                      class="shrink-0 text-[10px] px-1 py-0.5 rounded text-n-slate-11 hover:bg-n-alpha-2 opacity-0 group-hover:opacity-100 disabled:opacity-30"
                      :disabled="isFieldFullyInValues(field)"
                      :title="t('REPORT_PANELS.PIVOT.ADD_TO_VALUES')"
                      @click.stop="addFieldToValues(field)"
                    >
                      {{ t('REPORT_PANELS.PIVOT.ZONE_VALUES_SHORT') }}
                    </button>
                  </div>
                </template>
              </Draggable>
            </div>
          </div>
          <p
            class="px-3 py-2 text-[11px] text-n-slate-10 border-t border-n-weak"
          >
            {{ t('REPORT_PANELS.PIVOT.FIELDS_HINT') }}
          </p>
        </div>

        <!-- Zones -->
        <div class="flex flex-col gap-0 bg-n-solid-1">
          <!-- Filas chip -->
          <div class="px-3 py-2.5 border-b border-n-weak flex flex-col gap-1.5">
            <span
              class="text-xs font-semibold uppercase tracking-wide text-n-slate-11"
            >
              {{ t('REPORT_PANELS.PIVOT.ZONE_ROWS') }}
            </span>
            <div
              class="inline-flex items-center gap-2 self-start rounded-md border border-n-weak bg-n-background px-2.5 py-1 text-sm text-n-slate-12"
            >
              <Icon icon="i-lucide-list" class="size-3.5 text-n-slate-11" />
              {{ rowsLabel }}
            </div>
            <p class="text-[11px] text-n-slate-10">
              {{ t('REPORT_PANELS.PIVOT.ZONE_ROWS_HINT') }}
            </p>
          </div>

          <!-- Columnas -->
          <div class="px-3 py-2.5 border-b border-n-weak flex flex-col gap-2">
            <span
              class="text-xs font-semibold uppercase tracking-wide text-n-slate-11"
            >
              {{ t('REPORT_PANELS.PIVOT.ZONE_COLUMNS') }}
            </span>
            <p class="text-[11px] text-n-slate-10">
              {{ t('REPORT_PANELS.PIVOT.COLUMNS_HINT') }}
            </p>
            <SelectInput
              :model-value="ensurePivot().column_attribute"
              :options="pivotAttributeSelectOptions"
              full-width
              @update:model-value="setPivotAttribute"
            />
            <Draggable
              v-model="columnasDropList"
              :group="{ name: 'pivot-campos', put: true, pull: true }"
              item-key="id"
              class="min-h-[2.5rem] rounded-md border border-dashed border-n-weak px-2 py-1.5 flex flex-wrap gap-1.5 items-center"
              :class="{
                'border-n-brand bg-n-brand/5': dragging && !pivotField,
              }"
              @change="onColumnasChange"
            >
              <template #item="{ element: field }">
                <div
                  class="inline-flex items-center gap-1.5 rounded-md bg-n-background border border-n-weak px-2 py-1 text-sm text-n-slate-12"
                >
                  <Icon
                    icon="i-woot-drag-indicator"
                    class="size-3 text-n-slate-10 cursor-grab"
                  />
                  <span class="truncate max-w-[12rem]">{{ field.label }}</span>
                  <button
                    type="button"
                    class="text-n-slate-11 hover:text-n-ruby-11"
                    :aria-label="t('REPORT_PANELS.PIVOT.CLEAR_COLUMNS')"
                    @click="clearPivot"
                  >
                    <Icon icon="i-lucide-x" class="size-3.5" />
                  </button>
                </div>
              </template>
              <template #footer>
                <span
                  v-if="!columnasDropList.length"
                  class="text-xs text-n-slate-10"
                >
                  {{ t('REPORT_PANELS.PIVOT.DROP_COLUMN_FIELD') }}
                </span>
              </template>
            </Draggable>

            <template v-if="ensurePivot().column_attribute">
              <div
                v-if="pivotValueOptions.length"
                class="flex flex-col gap-1.5"
              >
                <span class="text-[11px] font-medium text-n-slate-11">
                  {{ t('REPORT_PANELS.PIVOT.COLUMN_VALUES') }}
                </span>
                <div class="flex flex-wrap gap-1.5">
                  <label
                    v-for="value in pivotValueOptions"
                    :key="value"
                    class="inline-flex items-center gap-1.5 rounded-md border border-n-weak bg-n-background px-2 py-1 text-xs text-n-slate-12 cursor-pointer hover:bg-n-alpha-2"
                  >
                    <input
                      type="checkbox"
                      :checked="isPivotValueSelected(value)"
                      @change="togglePivotValue(value)"
                    />
                    {{ value }}
                  </label>
                </div>
              </div>
              <p v-else class="text-[11px] text-n-slate-10">
                {{ t('REPORT_PANELS.PIVOT.COLUMN_VALUES_AUTO') }}
              </p>
              <label
                class="inline-flex items-center gap-2 text-xs text-n-slate-12"
              >
                <input
                  type="checkbox"
                  :checked="ensurePivot().show_row_totals !== false"
                  @change="
                    ensurePivot().show_row_totals = $event.target.checked
                  "
                />
                {{ t('REPORT_PANELS.PIVOT.SHOW_ROW_TOTALS') }}
              </label>
            </template>
          </div>

          <!-- Valores -->
          <div class="px-3 py-2.5 flex flex-col gap-2 flex-1">
            <span
              class="text-xs font-semibold uppercase tracking-wide text-n-slate-11"
            >
              {{ t('REPORT_PANELS.PIVOT.ZONE_VALUES') }}
            </span>
            <p class="text-[11px] text-n-slate-10">
              {{ t('REPORT_PANELS.PIVOT.VALUES_HINT') }}
            </p>

            <Draggable
              v-model="valoresList"
              :group="{ name: 'pivot-campos', put: true, pull: false }"
              :item-key="el => el.columnKey || el.id"
              handle=".measure-drag"
              class="flex flex-col gap-1.5 min-h-[3rem]"
              :class="{
                'rounded-md border border-dashed border-n-brand bg-n-brand/5 p-1':
                  dragging,
              }"
              @add="onValoresAdd"
              @end="onValoresReorder"
            >
              <template #item="{ element: row }">
                <div
                  class="flex flex-wrap items-center gap-2 rounded-md border border-n-weak bg-n-background px-2 py-1.5"
                >
                  <Icon
                    icon="i-woot-drag-indicator"
                    class="measure-drag size-3.5 shrink-0 text-n-slate-10 cursor-grab"
                  />
                  <span
                    class="text-sm text-n-slate-12 min-w-[6rem] flex-1 truncate"
                  >
                    {{ row.label }}
                  </span>
                  <SelectInput
                    v-if="row.isCustom"
                    :model-value="row.op"
                    :options="measureOpOptionsFor(row)"
                    class="min-w-[7rem]"
                    @update:model-value="op => changeMeasureOp(row, op)"
                  />
                  <SelectInput
                    v-else-if="showFooterAgg(row)"
                    :model-value="footerAggValue(row.columnKey)"
                    :options="footerAggregationOptions"
                    class="min-w-[7rem]"
                    @update:model-value="op => setFooterAgg(row.columnKey, op)"
                  />
                  <Button
                    icon="i-lucide-x"
                    variant="ghost"
                    color="slate"
                    xs
                    :aria-label="t('REPORT_PANELS.PIVOT.REMOVE_MEASURE')"
                    @click="removeMeasure(row.columnKey)"
                  />
                </div>
              </template>
            </Draggable>

            <p v-if="!valoresList.length" class="text-xs text-n-slate-10 py-1">
              {{ t('REPORT_PANELS.PIVOT.VALUES_EMPTY') }}
            </p>

            <!-- Compact add row -->
            <div
              class="flex flex-wrap items-end gap-2 pt-1 border-t border-n-weak"
            >
              <label
                class="flex flex-col gap-1 text-xs text-n-slate-11 flex-1 min-w-[10rem]"
              >
                {{ t('REPORT_PANELS.PIVOT.ADD_MEASURE') }}
                <SelectInput
                  v-model="addMeasureFieldId"
                  :options="addMeasureFieldOptions"
                  full-width
                />
              </label>
              <label
                v-if="
                  addMeasureFieldId &&
                  fieldById[addMeasureFieldId]?.kind !== 'system'
                "
                class="flex flex-col gap-1 text-xs text-n-slate-11 min-w-[7rem]"
              >
                {{ t('REPORT_PANELS.PIVOT.AGGREGATION') }}
                <SelectInput
                  v-model="addMeasureOp"
                  :options="addMeasureOpOptions"
                  full-width
                />
              </label>
              <Button
                :label="t('REPORT_PANELS.PIVOT.ADD')"
                size="sm"
                color="slate"
                :disabled="!addMeasureFieldId"
                @click="confirmAddMeasure"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Detail tables: searchable column picker -->
    <div v-else class="rounded-lg border border-n-weak p-3 flex flex-col gap-2">
      <span class="text-sm font-medium text-n-slate-12">
        {{ t('REPORT_PANELS.FIELDS.TABLE_COLUMNS') }}
      </span>
      <p class="text-xs text-n-slate-11">
        {{ t('REPORT_PANELS.FIELDS.TABLE_COLUMNS_HINT_DETAIL') }}
      </p>
      <Input
        v-model="detailSearch"
        :placeholder="t('REPORT_PANELS.PIVOT.FIELDS_SEARCH')"
        size="sm"
      />
      <div class="max-h-[18rem] overflow-y-auto flex flex-col gap-3">
        <div v-for="group in detailGroups" :key="group.key">
          <div
            class="text-[11px] font-medium uppercase tracking-wide text-n-slate-10 mb-1"
          >
            {{ group.label }}
          </div>
          <div class="flex flex-col gap-0.5">
            <label
              v-for="col in group.items"
              :key="col.key"
              class="inline-flex items-center gap-2 rounded-md px-1.5 py-1 text-sm text-n-slate-12 hover:bg-n-alpha-2 cursor-pointer"
            >
              <input
                type="checkbox"
                :checked="isDetailSelected(col.key)"
                @change="toggleDetailColumn(col.key)"
              />
              <span class="truncate">{{ col.label }}</span>
            </label>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
