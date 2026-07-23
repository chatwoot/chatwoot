<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import ReportHeader from '../components/ReportHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import PanelWidgetCard from './components/PanelWidgetCard.vue';
import SavedReportPanelsAPI from 'dashboard/api/savedReportPanels';
import { generateFileName } from 'dashboard/helper/downloadHelper';
import WootDatePicker from 'dashboard/components/ui/DatePicker/DatePicker.vue';
import { DATE_RANGE_TYPES } from 'dashboard/components/ui/DatePicker/helpers/DatePickerHelper';
import { getUnixStartOfDay, getUnixEndOfDay } from 'helpers/DateHelper';
import { panelPresetToRangeType, panelRangeToDates } from './panelConstants';
import format from 'date-fns/format';
import fromUnixTime from 'date-fns/fromUnixTime';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();
const { accountScopedRoute, currentAccount } = useAccount();
const contactAttributes = useMapGetter('attributes/getContactAttributes');
const conversationAttributes = useMapGetter(
  'attributes/getConversationAttributes'
);

const loading = ref(true);
const running = ref(false);
const panel = ref(null);
const runResult = ref(null);
const viewDateRange = ref([new Date(), new Date()]);
const viewRangeType = ref(DATE_RANGE_TYPES.CUSTOM_RANGE);
const usingOverride = ref(false);

const panelId = computed(() => route.params.id);

const ATTR_TYPE_MAP = {
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

const normalizeAttrDisplayType = attr => {
  const raw =
    attr?.attributeDisplayType ?? attr?.attribute_display_type ?? 'text';
  if (typeof raw === 'number') return ATTR_TYPE_MAP[raw] || 'text';
  return String(raw);
};

const attributeLabels = computed(() => {
  const map = {};
  (conversationAttributes.value || []).forEach(attr => {
    const key = attr.attributeKey || attr.attribute_key;
    const name = attr.attributeDisplayName || attr.attribute_display_name;
    map[key] = name;
    map[`ca:${key}`] = name;
  });
  (contactAttributes.value || []).forEach(attr => {
    const key = attr.attributeKey || attr.attribute_key;
    const name = attr.attributeDisplayName || attr.attribute_display_name;
    map[key] = name;
    map[`contact_ca:${key}`] = name;
  });
  return map;
});

const attributeTypes = computed(() => {
  const map = {};
  (conversationAttributes.value || []).forEach(attr => {
    const key = attr.attributeKey || attr.attribute_key;
    const type = normalizeAttrDisplayType(attr);
    map[key] = type;
    map[`ca:${key}`] = type;
  });
  (contactAttributes.value || []).forEach(attr => {
    const key = attr.attributeKey || attr.attribute_key;
    const type = normalizeAttrDisplayType(attr);
    map[key] = type;
    map[`contact_ca:${key}`] = type;
  });
  return map;
});

const resultByWidgetId = computed(() => {
  const map = {};
  (runResult.value?.widgets || []).forEach(widget => {
    map[widget.id] = widget;
  });
  return map;
});

const rangeDescription = computed(() => {
  if (panel.value?.description) return panel.value.description;
  if (usingOverride.value || panel.value?.date_preset === 'custom') {
    const since = runResult.value?.since;
    const until = runResult.value?.until;
    if (since && until) {
      return `${format(fromUnixTime(since), 'dd-MMM-yyyy')} → ${format(
        fromUnixTime(until),
        'dd-MMM-yyyy'
      )}`;
    }
    return t('REPORT_PANELS.DATE_PRESETS.CUSTOM');
  }
  const key = panel.value?.date_preset?.toUpperCase();
  return key ? t(`REPORT_PANELS.DATE_PRESETS.${key}`) : '';
});

const runParams = () => {
  const params = {
    timezone_offset: -new Date().getTimezoneOffset() / 60,
  };
  if (usingOverride.value) {
    params.since = getUnixStartOfDay(viewDateRange.value[0]);
    params.until = getUnixEndOfDay(viewDateRange.value[1]);
  }
  return params;
};

const runPanel = async () => {
  running.value = true;
  try {
    const { data } = await SavedReportPanelsAPI.run(panelId.value, runParams());
    runResult.value = data;
  } catch {
    useAlert(t('REPORT_PANELS.ERRORS.RUN'));
  } finally {
    running.value = false;
  }
};

const load = async () => {
  loading.value = true;
  try {
    await store.dispatch('attributes/get');
    const { data } = await SavedReportPanelsAPI.show(panelId.value);
    panel.value = data;
    viewDateRange.value = panelRangeToDates(data);
    viewRangeType.value = panelPresetToRangeType(data.date_preset);
    usingOverride.value = false;
    await runPanel();
  } catch {
    useAlert(t('REPORT_PANELS.ERRORS.LOAD'));
  } finally {
    loading.value = false;
  }
};

const onViewDateChange = value => {
  const [startDate, endDate, rangeType] = value;
  viewDateRange.value = [startDate, endDate];
  viewRangeType.value = rangeType || DATE_RANGE_TYPES.CUSTOM_RANGE;
  usingOverride.value = true;
  runPanel();
};

const resetToSavedRange = () => {
  if (!panel.value) return;
  viewDateRange.value = panelRangeToDates(panel.value);
  viewRangeType.value = panelPresetToRangeType(panel.value.date_preset);
  usingOverride.value = false;
  runPanel();
};

const editPanel = () => {
  router.push(accountScopedRoute('report_panels_edit', { id: panelId.value }));
};

const exportPanel = async () => {
  try {
    const { data } = await SavedReportPanelsAPI.export(
      panelId.value,
      runParams()
    );
    const fileName = generateFileName({
      type: `panel-${panel.value?.name || panelId.value}`,
      to: runResult.value?.until || Math.floor(Date.now() / 1000),
      accountName: currentAccount.value?.name,
      format: 'xlsx',
    });
    const url = URL.createObjectURL(
      new Blob([data], {
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      })
    );
    const link = document.createElement('a');
    link.href = url;
    link.download = fileName;
    link.click();
    URL.revokeObjectURL(url);
  } catch {
    useAlert(t('REPORT_PANELS.ERRORS.EXPORT'));
  }
};

const backToList = () => {
  router.push(accountScopedRoute('report_panels_index'));
};

onMounted(load);
</script>

<template>
  <div v-if="loading" class="flex justify-center py-16">
    <Spinner />
  </div>
  <template v-else-if="panel">
    <ReportHeader
      :header-title="panel.name"
      :header-description="rangeDescription"
    >
      <div class="flex items-center gap-2 flex-wrap">
        <Button
          :label="t('REPORT_PANELS.BACK')"
          variant="ghost"
          size="sm"
          @click="backToList"
        />
        <Button
          :label="t('REPORT_PANELS.EXPORT')"
          icon="i-ph-download-simple"
          size="sm"
          color="slate"
          @click="exportPanel"
        />
        <Button
          :label="t('REPORT_PANELS.EDIT')"
          icon="i-lucide-pencil"
          size="sm"
          color="slate"
          @click="editPanel"
        />
        <Button
          :label="t('REPORT_PANELS.REFRESH')"
          icon="i-lucide-refresh-cw"
          size="sm"
          :is-loading="running"
          @click="runPanel"
        />
      </div>
    </ReportHeader>

    <div
      class="flex flex-col md:flex-row md:items-center gap-3 mt-4 mb-2 flex-wrap"
    >
      <span class="text-sm text-n-slate-11">
        {{ t('REPORT_PANELS.FIELDS.VIEW_RANGE') }}
      </span>
      <WootDatePicker
        v-model:date-range="viewDateRange"
        v-model:range-type="viewRangeType"
        @date-range-changed="onViewDateChange"
      />
      <Button
        v-if="usingOverride"
        :label="t('REPORT_PANELS.RESET_RANGE')"
        size="sm"
        variant="ghost"
        @click="resetToSavedRange"
      />
    </div>

    <div class="grid gap-4 md:grid-cols-2 mt-4">
      <PanelWidgetCard
        v-for="widget in panel.widgets"
        :key="widget.id"
        :widget="widget"
        :result="resultByWidgetId[widget.id]"
        :attribute-labels="attributeLabels"
        :attribute-types="attributeTypes"
        :class="
          widget.type === 'chart' || widget.type === 'table'
            ? 'md:col-span-2'
            : ''
        "
      />
    </div>
  </template>
</template>
