<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import { formatTime } from '@chatwoot/utils';
import BarChart from 'shared/components/charts/BarChart.vue';
import { useAccount } from 'dashboard/composables/useAccount';
import {
  resolveTableColumns,
  isCustomAttributeColumn,
  customAttributeKeyFromColumn,
  parseLocaleNumber,
  formatNumericAttribute,
  SUMMABLE_CUSTOM_TYPES,
} from '../panelConstants';

const props = defineProps({
  widget: { type: Object, required: true },
  result: { type: Object, default: null },
  attributeLabels: { type: Object, default: () => ({}) },
  attributeTypes: { type: Object, default: () => ({}) },
});

const { t } = useI18n();
const router = useRouter();
const { accountScopedRoute } = useAccount();

const TIME_COLUMNS = new Set([
  'avg_first_response_time',
  'avg_resolution_time',
  'avg_reply_time',
  'reply_time',
]);

const DATE_COLUMNS = new Set(['created_at', 'last_activity_at']);

const sortKey = ref(null);
const sortDir = ref('asc'); // 'asc' | 'desc'

watch(
  () => props.result?.rows,
  () => {
    sortKey.value = null;
    sortDir.value = 'asc';
  }
);

const isTimeMetric = metric =>
  ['avg_first_response_time', 'avg_resolution_time', 'reply_time'].includes(
    metric
  );

const isAggregationSource = computed(
  () =>
    props.widget.source === 'aggregation' ||
    props.result?.source === 'aggregation'
);

const attributeTypes = computed(() => ({
  ...(props.attributeTypes || {}),
  ...(props.result?.attribute_types || {}),
}));

const aggregationFieldType = computed(() => {
  if (!isAggregationSource.value) return null;
  const field =
    props.widget.aggregation_field || props.result?.aggregation_field;
  if (!field) return null;
  const attrKey = customAttributeKeyFromColumn(field) || field;
  return (
    attributeTypes.value[field] ||
    attributeTypes.value[attrKey] ||
    attributeTypes.value[`ca:${attrKey}`] ||
    null
  );
});

const displayValue = computed(() => {
  if (!props.result || props.result.error) return '--';
  if (props.widget.type !== 'metric') return '';
  const value = props.result.value;
  if (value == null) return '--';
  if (!isAggregationSource.value && isTimeMetric(props.widget.metric)) {
    return formatTime(value);
  }
  const type = aggregationFieldType.value;
  if (type && SUMMABLE_CUSTOM_TYPES.has(type)) {
    return formatNumericAttribute(value, type);
  }
  return Number(value).toLocaleString();
});

const metricLabel = computed(() => {
  if (isAggregationSource.value) {
    const op = props.widget.aggregation_op || props.result?.aggregation_op;
    const field =
      props.widget.aggregation_field || props.result?.aggregation_field;
    const opLabel = op
      ? t(`REPORT_PANELS.AGGREGATIONS.${String(op).toUpperCase()}`)
      : '';
    if (!field) return opLabel;
    const attrKey = customAttributeKeyFromColumn(field) || field;
    const fieldLabel = props.attributeLabels[attrKey] || attrKey;
    return `${opLabel}: ${fieldLabel}`;
  }
  const metric = props.widget.metric;
  if (!metric) return '';
  return t(`REPORT_PANELS.METRICS.${metric}`);
});

const chartCollection = computed(() => {
  const points = props.result?.points || [];
  const timeMetric =
    !isAggregationSource.value && isTimeMetric(props.widget.metric);
  return {
    labels: points.map(point =>
      format(fromUnixTime(point.timestamp), 'dd-MMM')
    ),
    datasets: [
      {
        type: 'bar',
        // Dataset label = real metric (not custom title) so tooltips match data.
        label: timeMetric
          ? `${metricLabel.value} (${t('REPORT_PANELS.CHART_TIME_UNIT')})`
          : metricLabel.value || props.widget.title || '',
        data: points.map(point => {
          const value = Number(point.value) || 0;
          // Time metrics arrive as seconds — plot hours for readable scale.
          return timeMetric ? Math.round((value / 3600) * 10) / 10 : value;
        }),
        backgroundColor: 'rgba(37, 99, 235, 0.65)',
      },
    ],
  };
});
const tableKind = computed(
  () => props.widget.table_kind || props.result?.table_kind || 'agent_summary'
);

const tableRows = computed(() => props.result?.rows || []);

const tableHeaders = computed(() => {
  if (!tableRows.value.length && !props.value) return [];
  const configured = resolveTableColumns(tableKind.value, props.widget.columns);
  if (configured.length) {
    if (!tableRows.value.length) return configured;
    return configured.filter(
      key =>
        Object.prototype.hasOwnProperty.call(tableRows.value[0], key) ||
        isCustomAttributeColumn(key)
    );
  }
  return tableRows.value.length ? Object.keys(tableRows.value[0]) : [];
});

const columnType = key => {
  if (!isCustomAttributeColumn(key)) return null;
  const attrKey = customAttributeKeyFromColumn(key);
  return attributeTypes.value[key] || attributeTypes.value[attrKey] || null;
};

const sortValueFor = (row, key) => {
  const value = row?.[key];
  if (value == null || value === '') return null;

  const type = columnType(key);
  if (type && SUMMABLE_CUSTOM_TYPES.has(type)) {
    return parseLocaleNumber(value);
  }
  if (
    TIME_COLUMNS.has(key) ||
    DATE_COLUMNS.has(key) ||
    key === 'share_percent'
  ) {
    const num = Number(value);
    return Number.isFinite(num) ? num : null;
  }
  if (typeof value === 'number') return value;

  const asNum = parseLocaleNumber(value);
  if (asNum != null && /^-?[\d,.\s$%]+$/.test(String(value).trim())) {
    return asNum;
  }
  return String(value).toLocaleLowerCase();
};

const sortedTableRows = computed(() => {
  const rows = tableRows.value;
  if (!sortKey.value || !rows.length) return rows;

  const key = sortKey.value;
  const dir = sortDir.value === 'desc' ? -1 : 1;
  return [...rows].sort((a, b) => {
    const av = sortValueFor(a, key);
    const bv = sortValueFor(b, key);
    if (av == null && bv == null) return 0;
    if (av == null) return 1;
    if (bv == null) return -1;
    if (typeof av === 'number' && typeof bv === 'number') {
      return (av - bv) * dir;
    }
    return (
      String(av).localeCompare(String(bv), undefined, {
        numeric: true,
        sensitivity: 'base',
      }) * dir
    );
  });
});

const toggleSort = key => {
  if (sortKey.value === key) {
    sortDir.value = sortDir.value === 'asc' ? 'desc' : 'asc';
    return;
  }
  sortKey.value = key;
  sortDir.value = 'asc';
};

const sortIconClass = key => {
  if (sortKey.value !== key) return 'i-lucide-arrow-up-down text-n-slate-9';
  return sortDir.value === 'desc'
    ? 'i-lucide-arrow-down text-n-brand'
    : 'i-lucide-arrow-up text-n-brand';
};

const totals = computed(() => {
  const fromBackend = props.result?.totals;
  if (fromBackend && typeof fromBackend === 'object') {
    return {
      count:
        fromBackend.count ??
        props.result?.total_count ??
        tableRows.value.length,
      columns: fromBackend.columns || {},
      ops: fromBackend.ops || {},
    };
  }
  return {
    count: props.result?.total_count ?? tableRows.value.length,
    columns: {},
    ops: {},
  };
});

const hasFooterAggregations = computed(
  () => Object.keys(totals.value.columns || {}).length > 0
);

const rowsClickable = computed(() =>
  ['conversations', 'contacts'].includes(tableKind.value)
);

const headerLabel = key => {
  if (isCustomAttributeColumn(key)) {
    const attrKey = customAttributeKeyFromColumn(key);
    return (
      props.attributeLabels[key] || props.attributeLabels[attrKey] || attrKey
    );
  }
  const i18nKey = `REPORT_PANELS.COLUMNS.${key}`;
  const translated = t(i18nKey);
  return translated === i18nKey ? key : translated;
};

const formatCustomAttributeCell = (value, type) => {
  if (value == null || value === '') return '—';
  switch (type) {
    case 'checkbox':
      return value === true || value === 'true'
        ? t('FILTER.ATTRIBUTE_LABELS.TRUE')
        : t('FILTER.ATTRIBUTE_LABELS.FALSE');
    case 'date': {
      const date = new Date(value);
      return Number.isNaN(date.getTime())
        ? String(value)
        : date.toLocaleDateString();
    }
    case 'datetime': {
      const date = new Date(value);
      return Number.isNaN(date.getTime())
        ? String(value)
        : date.toLocaleString();
    }
    case 'number':
    case 'currency':
    case 'percent':
      return formatNumericAttribute(value, type);
    case 'list':
      return Array.isArray(value) ? value.join(', ') : String(value);
    default:
      return String(value);
  }
};

const formatCell = (row, key) => {
  const value = row[key];
  if (isCustomAttributeColumn(key)) {
    return formatCustomAttributeCell(value, columnType(key));
  }
  if (value == null || value === '') return '—';
  if (TIME_COLUMNS.has(key)) return formatTime(value);
  if (key === 'share_percent') return `${Number(value).toFixed(1)}%`;
  if (DATE_COLUMNS.has(key) && typeof value === 'number') {
    return format(fromUnixTime(value), 'dd-MMM-yyyy HH:mm');
  }
  if (key === 'status') {
    const statusKey = `CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${value}.TEXT`;
    const translated = t(statusKey);
    return translated === statusKey ? value : translated;
  }
  if (key === 'priority' && value) {
    const priorityKey = `CONVERSATION.PRIORITY.OPTIONS.${String(value).toUpperCase()}`;
    const translated = t(priorityKey);
    return translated === priorityKey ? value : translated;
  }
  if (key === 'labels') {
    return Array.isArray(value) ? value.join(', ') : String(value);
  }
  if (
    typeof value === 'number' &&
    !TIME_COLUMNS.has(key) &&
    !DATE_COLUMNS.has(key) &&
    key !== 'id' &&
    key !== 'rank'
  ) {
    return Number(value).toLocaleString();
  }
  return value;
};

const formatAggregateValue = (key, value) => {
  if (value == null || value === '') return '—';
  if (TIME_COLUMNS.has(key)) return formatTime(value);
  if (key === 'share_percent') return `${Number(value).toFixed(1)}%`;
  const type = columnType(key);
  if (type && SUMMABLE_CUSTOM_TYPES.has(type)) {
    return formatNumericAttribute(value, type);
  }
  return Number(value).toLocaleString();
};

const footerCell = key => {
  const value = totals.value.columns?.[key];
  if (value == null) return '';
  const op = totals.value.ops?.[key];
  const formatted = formatAggregateValue(key, value);
  if (!op) return formatted;
  const opLabel = t(`REPORT_PANELS.AGGREGATIONS.${String(op).toUpperCase()}`);
  return `${opLabel}: ${formatted}`;
};

const openRow = row => {
  if (!rowsClickable.value || row?.id == null) return;
  if (tableKind.value === 'conversations') {
    router.push(
      accountScopedRoute('inbox_conversation', {
        conversation_id: row.id,
      })
    );
    return;
  }
  if (tableKind.value === 'contacts') {
    router.push(
      accountScopedRoute('contacts_edit', {
        contactId: row.id,
      })
    );
  }
};

const title = computed(() => {
  if (props.widget.title) return props.widget.title;
  if (props.widget.type === 'table') {
    const kind = tableKind.value;
    const keyMap = {
      agent_summary: 'AGENT',
      inbox_summary: 'INBOX',
      team_summary: 'TEAM',
      label_summary: 'LABEL',
      conversations: 'CONVERSATIONS',
      contacts: 'CONTACTS',
    };
    return t(`REPORT_PANELS.TABLE_KINDS.${keyMap[kind] || 'AGENT'}`);
  }
  return metricLabel.value;
});

const tableSubtitle = computed(() => {
  if (props.widget.type !== 'table') return '';
  const total = totals.value.count;
  if (total == null) return '';
  return t('REPORT_PANELS.TOTALS.RECORDS_COUNT', { count: total });
});
</script>

<template>
  <div
    class="rounded-xl border border-n-weak bg-n-solid-2 p-4 flex flex-col gap-3 min-h-[10rem]"
  >
    <div class="flex flex-col gap-0.5">
      <h3 class="text-sm font-medium text-n-slate-12">{{ title }}</h3>
      <p v-if="tableSubtitle" class="text-xs text-n-slate-11">
        {{ tableSubtitle }}
      </p>
      <p
        v-else-if="widget.type !== 'table' && metricLabel"
        class="text-xs text-n-slate-11"
      >
        {{ metricLabel }}
      </p>
    </div>

    <div
      v-if="widget.type === 'metric'"
      class="text-3xl font-semibold text-n-slate-12"
    >
      {{ displayValue }}
    </div>

    <div v-else-if="widget.type === 'chart'" class="h-56">
      <BarChart :collection="chartCollection" />
    </div>

    <div v-else-if="widget.type === 'table'" class="flex flex-col gap-3">
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr>
              <th
                v-for="header in tableHeaders"
                :key="header"
                class="text-left py-2 px-2 text-n-slate-11 font-medium whitespace-nowrap select-none cursor-pointer hover:text-n-slate-12"
                :aria-sort="
                  sortKey === header
                    ? sortDir === 'desc'
                      ? 'descending'
                      : 'ascending'
                    : 'none'
                "
                @click="toggleSort(header)"
              >
                <span class="inline-flex items-center gap-1.5">
                  {{ headerLabel(header) }}
                  <span
                    class="size-3.5 shrink-0"
                    :class="sortIconClass(header)"
                  />
                </span>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="(row, index) in sortedTableRows"
              :key="index"
              class="border-t border-n-weak"
              :class="{
                'cursor-pointer hover:bg-n-alpha-black2': rowsClickable,
              }"
              @click="openRow(row)"
            >
              <td
                v-for="header in tableHeaders"
                :key="header"
                class="py-2 px-2 text-n-slate-12 whitespace-nowrap"
              >
                <span
                  v-if="rowsClickable && header === tableHeaders[0]"
                  class="text-n-brand font-medium"
                >
                  {{ formatCell(row, header) }}
                </span>
                <template v-else>
                  {{ formatCell(row, header) }}
                </template>
              </td>
            </tr>
          </tbody>
          <tfoot v-if="sortedTableRows.length && hasFooterAggregations">
            <tr class="border-t-2 border-n-weak bg-n-solid-1">
              <td
                v-for="(header, index) in tableHeaders"
                :key="`footer-${header}`"
                class="py-2 px-2 text-n-slate-12 whitespace-nowrap font-medium"
              >
                <template v-if="index === 0">
                  <span>{{ t('REPORT_PANELS.TOTALS.FOOTER_LABEL') }}</span>
                  <span v-if="footerCell(header)">
                    {{ ` · ${footerCell(header)}` }}
                  </span>
                </template>
                <template v-else>
                  {{ footerCell(header) }}
                </template>
              </td>
            </tr>
          </tfoot>
        </table>
        <p v-if="!tableRows.length" class="text-sm text-n-slate-11 py-4">
          {{ t('REPORT_PANELS.EMPTY_TABLE') }}
        </p>
        <p v-else-if="rowsClickable" class="text-xs text-n-slate-11 mt-2">
          {{ t('REPORT_PANELS.TABLE_CLICK_HINT') }}
        </p>
      </div>
    </div>

    <p v-if="result?.error" class="text-sm text-n-ruby-11">
      {{ result.error }}
    </p>
  </div>
</template>
