<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import formatDistanceStrict from 'date-fns/formatDistanceStrict';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import { formatDate, isActiveImport } from '../importStatus';
import { importSourceFor } from '../importSources';

const props = defineProps({
  dataImport: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const importTypeLabel = type => {
  if (type === 'contacts') return t('DATA_IMPORTS.TYPES.CONTACTS');
  if (type === 'conversations') return t('DATA_IMPORTS.TYPES.CONVERSATIONS');
  return type;
};

const importTypesLabel = computed(() => {
  const importTypes = props.dataImport?.import_types?.length
    ? props.dataImport.import_types
    : [props.dataImport?.data_type].filter(Boolean);

  return importTypes.map(importTypeLabel).join(', ');
});

const runDuration = computed(() => {
  const startedAt =
    props.dataImport?.started_at || props.dataImport?.created_at;
  if (!startedAt) return '-';

  const finishedAt =
    props.dataImport?.completed_at ||
    props.dataImport?.abandoned_at ||
    (isActiveImport(props.dataImport)
      ? new Date()
      : props.dataImport?.updated_at);
  if (!finishedAt) return '-';

  return formatDistanceStrict(new Date(startedAt), new Date(finishedAt));
});

const items = computed(() => [
  {
    key: 'source',
    icon: 'i-lucide-plug',
    label: t('DATA_IMPORTS.DETAIL.SOURCE'),
    value: importSourceFor(props.dataImport).label,
  },
  {
    key: 'import_types',
    icon: 'i-lucide-layers',
    label: t('DATA_IMPORTS.DETAIL.IMPORT_TYPES'),
    value: importTypesLabel.value || '-',
  },
  {
    key: 'created_at',
    icon: 'i-lucide-calendar',
    label: t('DATA_IMPORTS.DETAIL.CREATED'),
    value: formatDate(props.dataImport?.created_at),
  },
  {
    key: 'duration',
    icon: 'i-lucide-clock',
    label: t('DATA_IMPORTS.DETAIL.DURATION'),
    value: runDuration.value,
    tooltip: t('DATA_IMPORTS.DETAIL.LAST_UPDATED_TOOLTIP', {
      time: formatDate(props.dataImport?.updated_at),
    }),
  },
  {
    key: 'initiated_by',
    icon: 'i-lucide-user',
    label: t('DATA_IMPORTS.DETAIL.INITIATED_BY'),
    value:
      props.dataImport?.initiated_by?.name ||
      props.dataImport?.initiated_by?.email ||
      '-',
  },
]);
</script>

<template>
  <dl
    class="grid grid-cols-2 gap-px overflow-hidden rounded-xl border border-n-weak bg-n-weak sm:grid-cols-3 lg:grid-cols-5"
  >
    <div
      v-for="item in items"
      :key="item.key"
      class="flex min-w-0 flex-col gap-1 bg-n-solid-1 px-4 py-3"
    >
      <dt class="flex items-center gap-1.5 text-label-small text-n-slate-10">
        <Icon :icon="item.icon" class="size-3.5 shrink-0" />
        {{ item.label }}
      </dt>
      <dd
        v-tooltip.top="item.tooltip"
        class="truncate text-heading-3 text-n-slate-12"
      >
        {{ item.value }}
      </dd>
    </div>
  </dl>
</template>
