<script setup>
import { computed, h, onMounted, ref, useTemplateRef } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import ReportHeader from '../components/ReportHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import SelectInput from 'dashboard/components-next/select/Select.vue';
import ConditionRow from 'dashboard/components-next/filter/ConditionRow.vue';
import { useConversationFilterContext } from 'dashboard/components-next/filter/provider';
import { useOperators } from 'dashboard/components-next/filter/operators';
import { buildAttributesFilterTypes } from 'dashboard/components-next/filter/helper/filterHelper';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';
import SavedReportPanelsAPI from 'dashboard/api/savedReportPanels';
import {
  DATE_PRESETS,
  METRIC_OPTIONS,
  METRIC_SOURCES,
  AGGREGATION_OPS,
  AGGREGATION_ENTITIES,
  COLUMN_AGGREGATION_OPS,
  TABLE_KINDS,
  CONTACT_ATTR_PREFIX,
  CONTACT_FILTER_PREFIX,
  MULTI_SELECT_SYSTEM_KEYS,
  TABLE_COLUMN_OPTIONS,
  SUMMABLE_SYSTEM_COLUMNS,
  SUMMABLE_CUSTOM_TYPES,
  isCustomAttributeColumn,
  customAttributeColumnKey,
  contactCustomAttributeColumnKey,
  customAttributeKeyFromColumn,
  customAttributeMeasureColumnKey,
  measureOpFromColumn,
  measureBaseColumnKey,
  summaryMeasureOpsForAttrType,
  isContactCustomAttributeColumn,
  SUMMARY_TABLE_KINDS,
  PIVOT_COLUMN_ATTR_TYPES,
  MAX_PIVOT_VALUES,
  defaultPivotConfig,
  defaultColumnsForTableKind,
  defaultChartWidget,
  defaultMetricWidget,
  defaultTableWidget,
  emptyPanel,
  panelRangeToDates,
  resolveTableColumns,
} from './panelConstants';
import WootDatePicker from 'dashboard/components/ui/DatePicker/DatePicker.vue';
import { DATE_RANGE_TYPES } from 'dashboard/components/ui/DatePicker/helpers/DatePickerHelper';
import { getUnixStartOfDay, getUnixEndOfDay } from 'helpers/DateHelper';
import subDays from 'date-fns/subDays';

const props = defineProps({
  isNew: { type: Boolean, default: false },
});

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();
const { accountScopedRoute } = useAccount();
const { filterTypes } = useConversationFilterContext();
const contactAttributes = useMapGetter('attributes/getContactAttributes');
const conversationAttributes = useMapGetter(
  'attributes/getConversationAttributes'
);
const labels = useMapGetter('labels/getLabels');
const { getOperatorTypes, presenceOperators } = useOperators();

const saving = ref(false);
const form = ref(emptyPanel());
const uiFilters = ref([]);
const conditionsRef = useTemplateRef('conditionsRef');
const customDateRange = ref([subDays(new Date(), 6), new Date()]);
const customRangeType = ref(DATE_RANGE_TYPES.CUSTOM_RANGE);

const pageTitle = computed(() =>
  props.isNew ? t('REPORT_PANELS.CREATE') : t('REPORT_PANELS.EDIT')
);

const isCustomRange = computed(() => form.value.date_preset === 'custom');

const datePresetOptions = computed(() =>
  DATE_PRESETS.map(preset => ({
    value: preset.value,
    label: t(preset.labelKey),
  }))
);

const metricOptions = computed(() =>
  METRIC_OPTIONS.map(metric => ({
    value: metric,
    label: t(`REPORT_PANELS.METRICS.${metric}`),
  }))
);

const metricSourceOptions = computed(() =>
  METRIC_SOURCES.map(item => ({
    value: item.value,
    label: t(item.labelKey),
  }))
);

const aggregationOpOptions = computed(() =>
  AGGREGATION_OPS.map(item => ({
    value: item.value,
    label: t(item.labelKey),
  }))
);

const aggregationEntityOptions = computed(() =>
  AGGREGATION_ENTITIES.map(item => ({
    value: item.value,
    label: t(item.labelKey),
  }))
);

const columnAggregationOpOptions = computed(() =>
  COLUMN_AGGREGATION_OPS.map(item => ({
    value: item.value,
    label: t(item.labelKey),
  }))
);

const tableKindOptions = computed(() =>
  TABLE_KINDS.map(kind => ({
    value: kind.value,
    label: t(kind.labelKey),
  }))
);

const syncCustomDates = () => {
  form.value.custom_since = getUnixStartOfDay(customDateRange.value[0]);
  form.value.custom_until = getUnixEndOfDay(customDateRange.value[1]);
};

const onPresetChange = () => {
  if (!isCustomRange.value) {
    form.value.custom_since = null;
    form.value.custom_until = null;
    return;
  }
  const [from, to] = panelRangeToDates({ date_preset: 'last_7_days' });
  customDateRange.value = [from, to];
  syncCustomDates();
};

const onCustomDateChange = value => {
  const [startDate, endDate, rangeType] = value;
  customDateRange.value = [startDate, endDate];
  customRangeType.value = rangeType || DATE_RANGE_TYPES.CUSTOM_RANGE;
  syncCustomDates();
};

// Group system / conversation custom / contact filters for the builder.
const panelFilterTypes = computed(() => {
  const types = filterTypes.value || [];
  const system = types
    .filter(item => item.attributeModel !== 'customAttributes')
    .map(item => {
      let next = { ...item };
      if (MULTI_SELECT_SYSTEM_KEYS.has(item.attributeKey)) {
        next = { ...next, inputType: 'multiSelect' };
      }
      if (item.attributeKey === 'labels') {
        next = {
          ...next,
          attributeName: t('REPORT_PANELS.FILTERS.CONVERSATION_LABELS'),
          label: t('REPORT_PANELS.FILTERS.CONVERSATION_LABELS'),
        };
      }
      return next;
    });
  const conversationCustom = types.filter(
    item => item.attributeModel === 'customAttributes'
  );
  const contactLabelsKey = `${CONTACT_FILTER_PREFIX}labels`;
  const contactLabels = {
    attributeKey: contactLabelsKey,
    value: contactLabelsKey,
    attributeName: t('REPORT_PANELS.FILTERS.CONTACT_LABELS'),
    label: t('REPORT_PANELS.FILTERS.CONTACT_LABELS'),
    inputType: 'multiSelect',
    options: (labels.value || []).map(label => ({
      id: label.title,
      name: label.title,
      icon: h('span', {
        class: 'rounded-full',
        style: {
          backgroundColor: label.color,
          height: '6px',
          width: '6px',
        },
      }),
    })),
    dataType: 'text',
    filterOperators: presenceOperators.value,
    attributeModel: 'standard',
    customAttributeType: 'contact',
    sourceAttributeKey: 'labels',
  };
  const contactCustom = buildAttributesFilterTypes(
    contactAttributes.value || [],
    getOperatorTypes,
    'contact'
  ).map(item => {
    const keyed = `${CONTACT_ATTR_PREFIX}${item.attributeKey}`;
    return {
      ...item,
      attributeKey: keyed,
      value: keyed,
      sourceAttributeKey: item.attributeKey,
      customAttributeType: 'contact_attribute',
    };
  });

  const grouped = [];
  if (system.length) {
    grouped.push({
      value: '__system_attrs__',
      label: t('REPORT_PANELS.FILTERS.SYSTEM_ATTRIBUTES'),
      disabled: true,
    });
    grouped.push(...system);
  }
  if (conversationCustom.length) {
    grouped.push({
      value: '__custom_attrs__',
      label: t('REPORT_PANELS.FILTERS.CUSTOM_ATTRIBUTES'),
      disabled: true,
    });
    grouped.push(...conversationCustom);
  }
  grouped.push({
    value: '__contact_attrs__',
    label: t('REPORT_PANELS.FILTERS.CONTACT_ATTRIBUTES'),
    disabled: true,
  });
  grouped.push(contactLabels);
  if (contactCustom.length) {
    grouped.push({
      value: '__contact_custom_attrs__',
      label: t('REPORT_PANELS.FILTERS.CONTACT_CUSTOM_ATTRIBUTES'),
      disabled: true,
    });
    grouped.push(...contactCustom);
  }
  return grouped.length ? grouped : types;
});

const resolveFilterType = attributeKey =>
  panelFilterTypes.value.find(
    item => item.attributeKey === attributeKey || item.value === attributeKey
  );

const contactFilterLookupKey = filter => {
  if (filter.custom_attribute_type === 'contact_attribute') {
    return `${CONTACT_ATTR_PREFIX}${filter.attribute_key}`;
  }
  if (filter.custom_attribute_type === 'contact') {
    return `${CONTACT_FILTER_PREFIX}${filter.attribute_key}`;
  }
  return filter.attribute_key;
};

const hydrateFilterValues = (filter, types) => {
  const lookupKey = contactFilterLookupKey(filter);
  const type = types.find(
    item => item.attributeKey === lookupKey || item.value === lookupKey
  );
  const values = filter.values;
  if (!Array.isArray(values)) return values ?? [];
  if (!type) return values;

  if (type.inputType === 'multiSelect') {
    return values.map(id => {
      const option = type.options?.find(
        opt => opt.id === id || String(opt.id) === String(id)
      );
      return option || { id, name: String(id) };
    });
  }

  if (
    ['searchSelect', 'asyncSearchSelect', 'booleanSelect'].includes(
      type.inputType
    )
  ) {
    const id = values[0];
    const option = type.options?.find(
      opt => opt.id === id || String(opt.id) === String(id)
    );
    return option || { id, name: String(id) };
  }

  return values[0] ?? '';
};

const ensureWidgetDefaults = widget => {
  if (widget.type === 'metric' || widget.type === 'chart') {
    if (!widget.source) widget.source = 'preset';
    if (!widget.aggregation_op) widget.aggregation_op = 'count';
    if (widget.aggregation_field == null) widget.aggregation_field = '';
    if (widget.aggregation_group_field == null) {
      widget.aggregation_group_field = '';
    }
    if (!widget.aggregation_entity) widget.aggregation_entity = 'conversations';
  }
  if (widget.type === 'table' && !widget.column_aggregations) {
    widget.column_aggregations = {};
  }
  if (widget.type === 'table' && !widget.pivot) {
    widget.pivot = defaultPivotConfig();
  }
  return widget;
};

const loadExisting = async () => {
  if (props.isNew) return;
  try {
    const { data } = await SavedReportPanelsAPI.show(route.params.id);
    form.value = {
      name: data.name,
      description: data.description || '',
      date_preset: data.date_preset,
      custom_since: data.custom_since,
      custom_until: data.custom_until,
      business_hours: data.business_hours,
      favorite: data.favorite,
      filters: data.filters || [],
      widgets: (data.widgets || []).map(ensureWidgetDefaults),
    };
    if (data.date_preset === 'custom') {
      customDateRange.value = panelRangeToDates(data);
      customRangeType.value = DATE_RANGE_TYPES.CUSTOM_RANGE;
    }
    const types = panelFilterTypes.value || [];
    uiFilters.value = (data.filters || []).map(filter => ({
      attributeKey: contactFilterLookupKey(filter),
      filterOperator: filter.filter_operator,
      values: hydrateFilterValues(filter, types),
      queryOperator: filter.query_operator || 'and',
    }));
  } catch {
    useAlert(t('REPORT_PANELS.ERRORS.LOAD'));
  }
};

const addFilter = () => {
  if (uiFilters.value.length >= 10) {
    useAlert(t('REPORT_PANELS.ERRORS.MAX_FILTERS'));
    return;
  }
  uiFilters.value.push({
    attributeKey: 'status',
    filterOperator: 'equal_to',
    values: [],
    queryOperator: 'and',
  });
};

const removeFilter = index => {
  uiFilters.value.splice(index, 1);
};

const addWidget = type => {
  if (form.value.widgets.length >= 12) {
    useAlert(t('REPORT_PANELS.ERRORS.MAX_WIDGETS'));
    return;
  }
  if (type === 'metric') form.value.widgets.push(defaultMetricWidget());
  else if (type === 'chart') form.value.widgets.push(defaultChartWidget());
  else form.value.widgets.push(defaultTableWidget());
};

const removeWidget = index => {
  form.value.widgets.splice(index, 1);
};

const moveWidget = (index, direction) => {
  const target = index + direction;
  if (target < 0 || target >= form.value.widgets.length) return;
  const widgets = [...form.value.widgets];
  const [item] = widgets.splice(index, 1);
  widgets.splice(target, 0, item);
  form.value.widgets = widgets;
};

const onMetricSourceChange = widget => {
  if (widget.source === 'aggregation') {
    widget.aggregation_op = widget.aggregation_op || 'count';
    widget.aggregation_entity = widget.aggregation_entity || 'conversations';
    widget.aggregation_field = widget.aggregation_field || '';
    widget.aggregation_group_field = widget.aggregation_group_field || '';
  } else {
    widget.metric = widget.metric || 'conversations_count';
  }
};

const normalizeAttrDisplayType = attr => {
  const map = {
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
  const raw =
    attr?.attributeDisplayType ?? attr?.attribute_display_type ?? 'text';
  if (typeof raw === 'number') return map[raw] || 'text';
  return String(raw);
};

const aggregationFieldOptions = widget => {
  const entity = widget.aggregation_entity || 'conversations';
  const attrs =
    entity === 'contacts'
      ? contactAttributes.value || []
      : conversationAttributes.value || [];
  const op = widget.aggregation_op || 'count';
  // Count can target any attribute (non-empty presence). Sum/avg/min/max need numeric.
  const filtered =
    op === 'count'
      ? attrs
      : attrs.filter(attr =>
          SUMMABLE_CUSTOM_TYPES.has(normalizeAttrDisplayType(attr))
        );
  return filtered.map(attr => {
    const key = attr.attributeKey || attr.attribute_key;
    return {
      value: customAttributeColumnKey(key),
      label: attr.attributeDisplayName || attr.attribute_display_name || key,
    };
  });
};

const onAggregationOpChange = widget => {
  const field = widget.aggregation_field;
  if (!field) return;
  const allowed = new Set(
    aggregationFieldOptions(widget).map(item => item.value)
  );
  if (!allowed.has(field)) {
    widget.aggregation_field = '';
  }
};

const DATE_GROUP_ATTR_TYPES = new Set(['date', 'datetime']);

const aggregationGroupFieldOptions = widget => {
  const entity = widget.aggregation_entity || 'conversations';
  const attrs =
    entity === 'contacts'
      ? contactAttributes.value || []
      : conversationAttributes.value || [];
  return attrs
    .filter(attr => DATE_GROUP_ATTR_TYPES.has(normalizeAttrDisplayType(attr)))
    .map(attr => {
      const key = attr.attributeKey || attr.attribute_key;
      return {
        value: customAttributeColumnKey(key),
        label: attr.attributeDisplayName || attr.attribute_display_name || key,
      };
    });
};

const onTableKindChange = (widget, kind) => {
  if (kind !== undefined && kind !== null && kind !== '') {
    widget.table_kind = kind;
  }
  widget.columns = defaultColumnsForTableKind(widget.table_kind);
  widget.column_aggregations = {};
  if (!SUMMARY_TABLE_KINDS.has(widget.table_kind)) {
    widget.pivot = defaultPivotConfig();
  } else if (!widget.pivot) {
    widget.pivot = defaultPivotConfig();
  }
};

const mapAttrToColumnDef = (
  attr,
  { contact = false, numericOnly = false } = {}
) => {
  if (
    numericOnly &&
    !SUMMABLE_CUSTOM_TYPES.has(normalizeAttrDisplayType(attr))
  ) {
    return null;
  }
  const attributeKey = attr.attributeKey || attr.attribute_key;
  const name =
    attr.attributeDisplayName || attr.attribute_display_name || attributeKey;
  if (contact) {
    return {
      key: contactCustomAttributeColumnKey(attributeKey),
      label: t('REPORT_PANELS.COLUMNS.CONTACT_CA_PREFIX', { name }),
    };
  }
  return {
    key: customAttributeColumnKey(attributeKey),
    label: name,
  };
};

/** One selectable column per (attribute × measure) for summary tables. */
const mapAttrToMeasureColumnDefs = (attr, { contact = false } = {}) => {
  const attributeKey = attr.attributeKey || attr.attribute_key;
  if (!attributeKey) return [];
  const name =
    attr.attributeDisplayName || attr.attribute_display_name || attributeKey;
  const scopedName = contact
    ? t('REPORT_PANELS.COLUMNS.CONTACT_CA_PREFIX', { name })
    : t('REPORT_PANELS.COLUMNS.CONVERSATION_CA_PREFIX', { name });
  const type = normalizeAttrDisplayType(attr);
  return summaryMeasureOpsForAttrType(type).map(op => ({
    key: customAttributeMeasureColumnKey(attributeKey, op, { contact }),
    label: t('REPORT_PANELS.COLUMNS.MEASURE_CA', {
      op: t(`REPORT_PANELS.AGGREGATIONS.${op.toUpperCase()}`),
      name: scopedName,
    }),
    measureOp: op,
  }));
};

const customColumnDefsFor = widget => {
  const kind = widget.table_kind;
  if (kind === 'conversations') {
    return (conversationAttributes.value || [])
      .map(attr => mapAttrToColumnDef(attr))
      .filter(Boolean);
  }
  if (kind === 'contacts') {
    return (contactAttributes.value || [])
      .map(attr => mapAttrToColumnDef(attr))
      .filter(Boolean);
  }
  if (SUMMARY_TABLE_KINDS.has(kind)) {
    // All conversation + contact CAs: Count for every type; Sum/Avg/… for numeric.
    const conversationCols = (conversationAttributes.value || []).flatMap(
      attr => mapAttrToMeasureColumnDefs(attr, { contact: false })
    );
    const contactCols = (contactAttributes.value || []).flatMap(attr =>
      mapAttrToMeasureColumnDefs(attr, { contact: true })
    );
    return [...conversationCols, ...contactCols];
  }
  return [];
};

const columnOptionsFor = widget => {
  const system = TABLE_COLUMN_OPTIONS[widget.table_kind] || [];
  return [...system, ...customColumnDefsFor(widget).map(item => item.key)];
};

const selectedColumnsFor = widget => {
  if (Array.isArray(widget.columns) && widget.columns.length) {
    return [...widget.columns];
  }
  return defaultColumnsForTableKind(widget.table_kind);
};

const columnLabel = (widget, key) => {
  if (isCustomAttributeColumn(key)) {
    const baseKey = measureOpFromColumn(key) ? measureBaseColumnKey(key) : key;
    const def = customColumnDefsFor(widget).find(item => item.key === baseKey);
    return def?.label || customAttributeKeyFromColumn(baseKey) || key;
  }
  return t(`REPORT_PANELS.COLUMNS.${key}`);
};

const isColumnSelected = (widget, key) =>
  selectedColumnsFor(widget).includes(key);

const toggleColumn = (widget, key) => {
  const allowed = new Set(columnOptionsFor(widget));
  let cols = selectedColumnsFor(widget);
  if (cols.includes(key)) {
    cols = cols.filter(item => item !== key);
    if (widget.column_aggregations?.[key] != null) {
      const next = { ...widget.column_aggregations };
      delete next[key];
      widget.column_aggregations = next;
    }
  } else {
    cols.push(key);
    const bakedOp = measureOpFromColumn(key);
    if (
      SUMMARY_TABLE_KINDS.has(widget.table_kind) &&
      isCustomAttributeColumn(key) &&
      !widget.column_aggregations?.[key]
    ) {
      const footerOp =
        !bakedOp || bakedOp === 'count' || bakedOp === 'sum' ? 'sum' : bakedOp;
      widget.column_aggregations = {
        ...(widget.column_aggregations || {}),
        [key]: footerOp,
      };
    }
  }
  widget.columns = cols.filter(
    item => allowed.has(item) || isCustomAttributeColumn(item)
  );
  if (!widget.columns.length) {
    widget.columns = defaultColumnsForTableKind(widget.table_kind);
  }
};

const attributeTypeForColumn = (widget, key) => {
  if (!isCustomAttributeColumn(key)) return null;
  const attrKey = customAttributeKeyFromColumn(key);
  const pool = isContactCustomAttributeColumn(key)
    ? contactAttributes.value || []
    : conversationAttributes.value || [];
  const match = pool.find(
    attr => (attr.attributeKey || attr.attribute_key) === attrKey
  );
  return match ? normalizeAttrDisplayType(match) : '';
};

const ensurePivot = widget => {
  if (!widget.pivot) widget.pivot = defaultPivotConfig();
  return widget.pivot;
};

const pivotAttributeOptions = computed(() => {
  const attrs = conversationAttributes.value || [];
  return [
    {
      value: '',
      label: t('REPORT_PANELS.PIVOT.NONE'),
    },
    ...attrs
      .filter(attr =>
        PIVOT_COLUMN_ATTR_TYPES.has(normalizeAttrDisplayType(attr))
      )
      .map(attr => {
        const key = attr.attributeKey || attr.attribute_key;
        const name =
          attr.attributeDisplayName || attr.attribute_display_name || key;
        return { value: customAttributeColumnKey(key), label: name };
      }),
  ];
});

const pivotDefinitionFor = attributeKey => {
  if (!attributeKey) return null;
  const key = attributeKey.replace(/^ca:/, '');
  return (conversationAttributes.value || []).find(
    attr => (attr.attributeKey || attr.attribute_key) === key
  );
};

const pivotValueOptions = widget => {
  const pivot = ensurePivot(widget);
  const def = pivotDefinitionFor(pivot.column_attribute);
  const values = def?.attributeValues || def?.attribute_values || [];
  return Array.isArray(values)
    ? values.filter(Boolean).slice(0, MAX_PIVOT_VALUES)
    : [];
};

const isPivotValueSelected = (widget, value) => {
  const selected = ensurePivot(widget).column_values;
  // Empty selection = all values (Excel default)
  if (!Array.isArray(selected) || !selected.length) return true;
  return selected.includes(value);
};

const togglePivotValue = (widget, value) => {
  const pivot = ensurePivot(widget);
  const all = pivotValueOptions(widget);
  let selected = Array.isArray(pivot.column_values)
    ? [...pivot.column_values]
    : [];
  // First explicit toggle from "all" → start with all except this one, or only this one?
  // Excel: unchecked removes from set. From "all", first uncheck = all minus that value.
  if (!selected.length) {
    selected = all.filter(item => item !== value);
  } else if (selected.includes(value)) {
    selected = selected.filter(item => item !== value);
  } else {
    selected.push(value);
  }
  // If user re-selected everything, store [] (= all)
  pivot.column_values =
    selected.length === all.length ? [] : selected.slice(0, MAX_PIVOT_VALUES);
};

const setPivotAttribute = (widget, attributeKey) => {
  const pivot = ensurePivot(widget);
  pivot.column_attribute = attributeKey || '';
  pivot.column_values = [];
};

const isMeasureColumnKey = key => Boolean(measureOpFromColumn(key));

const isAggregatableColumnKey = (widget, key) => {
  if (isMeasureColumnKey(key)) return false;
  if (SUMMABLE_SYSTEM_COLUMNS.has(key)) return true;
  return SUMMABLE_CUSTOM_TYPES.has(attributeTypeForColumn(widget, key));
};

const columnAggregationValue = (widget, key) =>
  widget.column_aggregations?.[key] || '';

const setColumnAggregation = (widget, key, op) => {
  // Materialize columns so aggregations are not stripped on save when
  // the UI was showing defaults with an empty columns array.
  if (!Array.isArray(widget.columns) || !widget.columns.length) {
    widget.columns = defaultColumnsForTableKind(widget.table_kind);
  }
  if (!widget.columns.includes(key)) {
    widget.columns = [...widget.columns, key];
  }
  const next = { ...(widget.column_aggregations || {}) };
  if (!op) delete next[key];
  else next[key] = op;
  widget.column_aggregations = next;
};

const buildPayload = () => {
  let filters = [];
  if (uiFilters.value.length) {
    const generated = filterQueryGenerator(
      uiFilters.value.map(filter => {
        const type = resolveFilterType(filter.attributeKey);
        const isContactCustom =
          type?.customAttributeType === 'contact_attribute';
        const isContactEntity = type?.customAttributeType === 'contact';
        const attributeKey =
          isContactCustom || isContactEntity
            ? type.sourceAttributeKey
            : filter.attributeKey.replace(
                new RegExp(`^${CONTACT_ATTR_PREFIX}|^${CONTACT_FILTER_PREFIX}`),
                ''
              );
        let customAttributeType = '';
        if (isContactCustom) customAttributeType = 'contact_attribute';
        else if (isContactEntity) customAttributeType = 'contact';
        return {
          attribute_key: attributeKey,
          filter_operator: filter.filterOperator,
          values: filter.values,
          query_operator: filter.queryOperator,
          custom_attribute_type: customAttributeType,
        };
      })
    );
    filters = generated.payload || [];
  }
  const widgets = form.value.widgets.map(widget => {
    const next = { ...ensureWidgetDefaults({ ...widget }) };
    if (next.type === 'table') {
      next.columns = resolveTableColumns(next.table_kind, next.columns);
      const aggregations = next.column_aggregations || {};
      next.column_aggregations = Object.fromEntries(
        Object.entries(aggregations).filter(
          ([key, op]) => next.columns.includes(key) && Boolean(op)
        )
      );
      if (
        SUMMARY_TABLE_KINDS.has(next.table_kind) &&
        next.pivot?.column_attribute
      ) {
        next.pivot = {
          column_attribute: next.pivot.column_attribute,
          column_values: Array.isArray(next.pivot.column_values)
            ? next.pivot.column_values.slice(0, MAX_PIVOT_VALUES)
            : [],
          show_row_totals: next.pivot.show_row_totals !== false,
        };
      } else {
        next.pivot = defaultPivotConfig();
      }
    }
    return next;
  });
  return {
    saved_report_panel: {
      ...form.value,
      widgets,
      filters,
    },
  };
};

const save = async () => {
  if (!form.value.name.trim()) {
    useAlert(t('REPORT_PANELS.ERRORS.NAME_REQUIRED'));
    return;
  }
  if (!form.value.widgets.length) {
    useAlert(t('REPORT_PANELS.ERRORS.WIDGET_REQUIRED'));
    return;
  }
  if (form.value.date_preset === 'custom') {
    syncCustomDates();
    if (!form.value.custom_since || !form.value.custom_until) {
      useAlert(t('REPORT_PANELS.ERRORS.CUSTOM_RANGE_REQUIRED'));
      return;
    }
  }
  if (uiFilters.value.length) {
    const rows = [].concat(conditionsRef.value || []);
    const valid =
      rows.length === uiFilters.value.length &&
      rows.every(row => row.validate());
    if (!valid) {
      useAlert(t('REPORT_PANELS.ERRORS.FILTERS_INVALID'));
      return;
    }
  }
  saving.value = true;
  try {
    const payload = buildPayload();
    if (props.isNew) {
      const { data } = await SavedReportPanelsAPI.create(payload);
      router.replace(accountScopedRoute('report_panels_show', { id: data.id }));
    } else {
      await SavedReportPanelsAPI.update(route.params.id, payload);
      router.push(
        accountScopedRoute('report_panels_show', { id: route.params.id })
      );
    }
  } catch {
    useAlert(t('REPORT_PANELS.ERRORS.SAVE'));
  } finally {
    saving.value = false;
  }
};

const destroyPanel = async () => {
  if (props.isNew) return;
  try {
    await SavedReportPanelsAPI.delete(route.params.id);
    router.push(accountScopedRoute('report_panels_index'));
  } catch {
    useAlert(t('REPORT_PANELS.ERRORS.SAVE'));
  }
};

const cancelEdit = () => {
  if (props.isNew) {
    router.push(accountScopedRoute('report_panels_index'));
    return;
  }
  router.push(
    accountScopedRoute('report_panels_show', { id: route.params.id })
  );
};

onMounted(async () => {
  await Promise.all([
    store.dispatch('attributes/get'),
    store.dispatch('agents/get'),
    store.dispatch('inboxes/get'),
    store.dispatch('teams/get'),
    store.dispatch('labels/get'),
    store.dispatch('campaigns/get'),
  ]);
  await loadExisting();
});
</script>

<template>
  <ReportHeader :header-title="pageTitle">
    <div class="flex gap-2">
      <Button
        :label="t('REPORT_PANELS.BACK')"
        variant="ghost"
        size="sm"
        @click="cancelEdit"
      />
      <Button
        v-if="!isNew"
        :label="t('REPORT_PANELS.DELETE')"
        color="ruby"
        variant="ghost"
        size="sm"
        @click="destroyPanel"
      />
      <Button
        :label="t('REPORT_PANELS.SAVE')"
        size="sm"
        :is-loading="saving"
        @click="save"
      />
    </div>
  </ReportHeader>

  <div class="flex flex-col gap-6 mt-4 max-w-4xl">
    <section class="flex flex-col gap-4">
      <Input
        v-model="form.name"
        :label="t('REPORT_PANELS.FIELDS.NAME')"
        :placeholder="t('REPORT_PANELS.FIELDS.NAME_PLACEHOLDER')"
      />
      <TextArea
        v-model="form.description"
        :label="t('REPORT_PANELS.FIELDS.DESCRIPTION')"
        auto-height
        min-height="5.5rem"
      />
      <label class="text-sm text-n-slate-12 flex flex-col gap-1.5">
        {{ t('REPORT_PANELS.FIELDS.DATE_PRESET') }}
        <SelectInput
          v-model="form.date_preset"
          :options="datePresetOptions"
          full-width
          @update:model-value="onPresetChange"
        />
      </label>
      <div v-if="isCustomRange" class="flex flex-col gap-2">
        <span class="text-sm text-n-slate-12">
          {{ t('REPORT_PANELS.FIELDS.CUSTOM_RANGE') }}
        </span>
        <WootDatePicker
          v-model:date-range="customDateRange"
          v-model:range-type="customRangeType"
          @date-range-changed="onCustomDateChange"
        />
      </div>
      <div class="flex flex-col gap-2">
        <label class="inline-flex items-center gap-2 text-sm text-n-slate-12">
          <input v-model="form.business_hours" type="checkbox" />
          {{ t('REPORT_PANELS.FIELDS.BUSINESS_HOURS') }}
        </label>
        <label class="inline-flex items-center gap-2 text-sm text-n-slate-12">
          <input v-model="form.favorite" type="checkbox" />
          {{ t('REPORT_PANELS.FIELDS.FAVORITE') }}
        </label>
      </div>
    </section>

    <section class="rounded-xl border border-n-weak p-4">
      <div class="flex items-center justify-between mb-3">
        <h3 class="font-medium text-n-slate-12">
          {{ t('REPORT_PANELS.FILTERS.TITLE') }}
        </h3>
        <Button
          :label="t('REPORT_PANELS.FILTERS.ADD')"
          size="sm"
          variant="ghost"
          @click="addFilter"
        />
      </div>
      <p class="text-sm text-n-slate-11 mb-3">
        {{ t('REPORT_PANELS.FILTERS.HINT') }}
      </p>
      <div v-if="uiFilters.length" class="flex flex-col gap-2">
        <!--
          query_operator lives on the PREVIOUS filter (how it joins the next).
          Show AND/OR on rows after the first, bound to filters[index - 1],
          matching ConversationFilter / AutomationRuleForm.
          Sanity: payload shape is [{..., query_operator: 'and'|'or'}, {..., query_operator: undefined}].
          Runner applies FilterService left-to-right with those operators (AND vs OR differ).
        -->
        <template v-for="(filter, index) in uiFilters" :key="index">
          <ConditionRow
            v-if="index === 0"
            ref="conditionsRef"
            v-model:attribute-key="filter.attributeKey"
            v-model:filter-operator="filter.filterOperator"
            v-model:values="filter.values"
            :filter-types="panelFilterTypes"
            :show-query-operator="false"
            @remove="removeFilter(index)"
          />
          <ConditionRow
            v-else
            ref="conditionsRef"
            v-model:attribute-key="filter.attributeKey"
            v-model:filter-operator="filter.filterOperator"
            v-model:values="filter.values"
            v-model:query-operator="uiFilters[index - 1].queryOperator"
            :filter-types="panelFilterTypes"
            show-query-operator
            @remove="removeFilter(index)"
          />
        </template>
      </div>
      <p v-else class="text-sm text-n-slate-11">
        {{ t('REPORT_PANELS.FILTERS.EMPTY') }}
      </p>
    </section>

    <section class="rounded-xl border border-n-weak p-4">
      <div class="flex items-center justify-between mb-3 gap-2 flex-wrap">
        <h3 class="font-medium text-n-slate-12">
          {{ t('REPORT_PANELS.WIDGETS.TITLE') }}
        </h3>
        <div class="flex gap-2">
          <Button
            :label="t('REPORT_PANELS.WIDGETS.ADD_METRIC')"
            size="sm"
            variant="ghost"
            @click="addWidget('metric')"
          />
          <Button
            :label="t('REPORT_PANELS.WIDGETS.ADD_CHART')"
            size="sm"
            variant="ghost"
            @click="addWidget('chart')"
          />
          <Button
            :label="t('REPORT_PANELS.WIDGETS.ADD_TABLE')"
            size="sm"
            variant="ghost"
            @click="addWidget('table')"
          />
        </div>
      </div>

      <div
        v-for="(widget, index) in form.widgets"
        :key="widget.id"
        class="mb-3 rounded-lg border border-n-weak p-3 grid gap-2"
      >
        <div class="flex justify-between items-center gap-2 flex-wrap">
          <span class="text-sm font-medium text-n-slate-12">{{
            t(`REPORT_PANELS.WIDGETS.TYPES.${widget.type.toUpperCase()}`)
          }}</span>
          <div class="flex gap-1 items-center">
            <Button
              :label="t('REPORT_PANELS.WIDGETS.MOVE_UP')"
              size="sm"
              variant="ghost"
              :disabled="index === 0"
              @click="moveWidget(index, -1)"
            />
            <Button
              :label="t('REPORT_PANELS.WIDGETS.MOVE_DOWN')"
              size="sm"
              variant="ghost"
              :disabled="index === form.widgets.length - 1"
              @click="moveWidget(index, 1)"
            />
            <Button
              :label="t('REPORT_PANELS.WIDGETS.REMOVE')"
              size="sm"
              variant="ghost"
              color="ruby"
              @click="removeWidget(index)"
            />
          </div>
        </div>
        <Input
          v-model="widget.title"
          :label="t('REPORT_PANELS.FIELDS.WIDGET_TITLE')"
        />
        <template v-if="widget.type === 'metric' || widget.type === 'chart'">
          <label class="text-sm text-n-slate-12 flex flex-col gap-1.5">
            {{ t('REPORT_PANELS.FIELDS.METRIC_SOURCE') }}
            <SelectInput
              v-model="widget.source"
              :options="metricSourceOptions"
              full-width
              @update:model-value="() => onMetricSourceChange(widget)"
            />
          </label>
          <label
            v-if="widget.source !== 'aggregation'"
            class="text-sm text-n-slate-12 flex flex-col gap-1.5"
          >
            {{ t('REPORT_PANELS.FIELDS.METRIC') }}
            <SelectInput
              v-model="widget.metric"
              :options="metricOptions"
              full-width
            />
          </label>
          <template v-else>
            <label class="text-sm text-n-slate-12 flex flex-col gap-1.5">
              {{ t('REPORT_PANELS.FIELDS.AGGREGATION_ENTITY') }}
              <SelectInput
                v-model="widget.aggregation_entity"
                :options="aggregationEntityOptions"
                full-width
                @update:model-value="
                  () => {
                    widget.aggregation_field = '';
                    widget.aggregation_group_field = '';
                  }
                "
              />
            </label>
            <label class="text-sm text-n-slate-12 flex flex-col gap-1.5">
              {{ t('REPORT_PANELS.FIELDS.AGGREGATION_OP') }}
              <SelectInput
                v-model="widget.aggregation_op"
                :options="aggregationOpOptions"
                full-width
                @update:model-value="() => onAggregationOpChange(widget)"
              />
            </label>
            <label
              v-if="widget.aggregation_op !== 'count'"
              class="text-sm text-n-slate-12 flex flex-col gap-1.5"
            >
              {{ t('REPORT_PANELS.FIELDS.AGGREGATION_FIELD') }}
              <SelectInput
                v-model="widget.aggregation_field"
                :options="aggregationFieldOptions(widget)"
                full-width
              />
            </label>
            <p
              v-else-if="aggregationFieldOptions(widget).length"
              class="text-xs text-n-slate-11"
            >
              {{ t('REPORT_PANELS.FIELDS.AGGREGATION_FIELD_OPTIONAL_HINT') }}
            </p>
            <label
              v-if="
                widget.aggregation_op === 'count' &&
                aggregationFieldOptions(widget).length
              "
              class="text-sm text-n-slate-12 flex flex-col gap-1.5"
            >
              {{ t('REPORT_PANELS.FIELDS.AGGREGATION_FIELD_OPTIONAL') }}
              <SelectInput
                v-model="widget.aggregation_field"
                :options="[
                  {
                    value: '',
                    label: t('REPORT_PANELS.AGGREGATIONS.ALL_ROWS'),
                  },
                  ...aggregationFieldOptions(widget),
                ]"
                full-width
              />
            </label>
            <label
              v-if="aggregationGroupFieldOptions(widget).length"
              class="text-sm text-n-slate-12 flex flex-col gap-1.5"
            >
              {{ t('REPORT_PANELS.FIELDS.AGGREGATION_GROUP_FIELD') }}
              <SelectInput
                v-model="widget.aggregation_group_field"
                :options="[
                  {
                    value: '',
                    label: t('REPORT_PANELS.AGGREGATIONS.GROUP_BY_CREATED_AT'),
                  },
                  ...aggregationGroupFieldOptions(widget),
                ]"
                full-width
              />
            </label>
            <p
              v-if="aggregationGroupFieldOptions(widget).length"
              class="text-xs text-n-slate-11"
            >
              {{ t('REPORT_PANELS.FIELDS.AGGREGATION_GROUP_FIELD_HINT') }}
            </p>
          </template>
        </template>
        <label
          v-if="widget.type === 'table'"
          class="text-sm text-n-slate-12 flex flex-col gap-1.5"
        >
          {{ t('REPORT_PANELS.PIVOT.ROWS') }}
          <SelectInput
            v-model="widget.table_kind"
            :options="tableKindOptions"
            full-width
            @update:model-value="kind => onTableKindChange(widget, kind)"
          />
          <span class="text-xs text-n-slate-11">
            {{ t('REPORT_PANELS.PIVOT.ROWS_HINT') }}
          </span>
        </label>
        <div
          v-if="
            widget.type === 'table' &&
            SUMMARY_TABLE_KINDS.has(widget.table_kind)
          "
          class="rounded-lg border border-n-weak p-3 flex flex-col gap-2"
        >
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('REPORT_PANELS.PIVOT.COLUMNS') }}
          </span>
          <p class="text-xs text-n-slate-11">
            {{ t('REPORT_PANELS.PIVOT.COLUMNS_HINT') }}
          </p>
          <label class="text-sm text-n-slate-12 flex flex-col gap-1.5">
            {{ t('REPORT_PANELS.PIVOT.COLUMN_FIELD') }}
            <SelectInput
              :model-value="ensurePivot(widget).column_attribute"
              :options="pivotAttributeOptions"
              full-width
              @update:model-value="value => setPivotAttribute(widget, value)"
            />
          </label>
          <div
            v-if="ensurePivot(widget).column_attribute"
            class="flex flex-col gap-2"
          >
            <span class="text-xs font-medium text-n-slate-11">
              {{ t('REPORT_PANELS.PIVOT.COLUMN_VALUES') }}
            </span>
            <p class="text-xs text-n-slate-11">
              {{ t('REPORT_PANELS.PIVOT.COLUMN_VALUES_HINT') }}
            </p>
            <div
              v-if="pivotValueOptions(widget).length"
              class="flex flex-wrap gap-2"
            >
              <label
                v-for="value in pivotValueOptions(widget)"
                :key="value"
                class="inline-flex items-center gap-1.5 text-sm text-n-slate-12"
              >
                <input
                  type="checkbox"
                  :checked="isPivotValueSelected(widget, value)"
                  @change="togglePivotValue(widget, value)"
                />
                {{ value }}
              </label>
            </div>
            <p v-else class="text-xs text-n-slate-11">
              {{ t('REPORT_PANELS.PIVOT.COLUMN_VALUES_AUTO') }}
            </p>
            <label
              class="inline-flex items-center gap-2 text-sm text-n-slate-12"
            >
              <input
                type="checkbox"
                :checked="ensurePivot(widget).show_row_totals !== false"
                @change="
                  ensurePivot(widget).show_row_totals = $event.target.checked
                "
              />
              {{ t('REPORT_PANELS.PIVOT.SHOW_ROW_TOTALS') }}
            </label>
          </div>
        </div>
        <div
          v-if="widget.type === 'table' && columnOptionsFor(widget).length"
          class="rounded-lg border border-n-weak p-3 flex flex-col gap-2"
        >
          <span class="text-sm font-medium text-n-slate-12">
            {{
              SUMMARY_TABLE_KINDS.has(widget.table_kind)
                ? t('REPORT_PANELS.PIVOT.VALUES')
                : t('REPORT_PANELS.FIELDS.TABLE_COLUMNS')
            }}
          </span>
          <p class="text-xs text-n-slate-11">
            {{
              SUMMARY_TABLE_KINDS.has(widget.table_kind)
                ? t('REPORT_PANELS.PIVOT.VALUES_HINT')
                : t('REPORT_PANELS.FIELDS.TABLE_COLUMNS_HINT')
            }}
          </p>
          <div class="flex flex-col gap-2">
            <div
              v-for="columnKey in columnOptionsFor(widget)"
              :key="columnKey"
              class="flex flex-wrap items-center gap-2 text-sm text-n-slate-12"
            >
              <label class="inline-flex items-center gap-2 min-w-[12rem]">
                <input
                  type="checkbox"
                  :checked="isColumnSelected(widget, columnKey)"
                  @change="toggleColumn(widget, columnKey)"
                />
                {{ columnLabel(widget, columnKey) }}
              </label>
              <SelectInput
                v-if="
                  isColumnSelected(widget, columnKey) &&
                  isAggregatableColumnKey(widget, columnKey)
                "
                :model-value="columnAggregationValue(widget, columnKey)"
                :options="columnAggregationOpOptions"
                class="min-w-[8rem]"
                @update:model-value="
                  op => setColumnAggregation(widget, columnKey, op)
                "
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>
