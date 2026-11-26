<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  dataImport: {
    type: Object,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
});

const { t } = useI18n();
const progressCaption = (hasTotal, total) => {
  if (!hasTotal) return t('DATA_IMPORTS.DETAIL.PROGRESS_IMPORTED');
  const values = { total: total.toLocaleString() };
  if (props.dataImport.source_provider === 'csv')
    return t('DATA_IMPORTS.CSV.PROCESSED', values);
  return t('DATA_IMPORTS.DETAIL.PROGRESS_OF_TOTAL', values);
};

const items = computed(() => {
  const importTypes = props.dataImport?.import_types || [];
  const groups = [];
  if (importTypes.includes('contacts')) {
    groups.push({ key: 'contacts', label: t('DATA_IMPORTS.TYPES.CONTACTS') });
  }
  if (importTypes.includes('conversations')) {
    groups.push(
      { key: 'conversations', label: t('DATA_IMPORTS.TYPES.CONVERSATIONS') },
      { key: 'messages', label: t('DATA_IMPORTS.TYPES.MESSAGES') }
    );
  }

  return groups.map(({ key, label }) => {
    const stats = props.dataImport?.stats?.[key] || {};
    const imported = Number(stats.processed ?? stats.imported ?? 0);
    const hasTotal = stats.total !== undefined && stats.total !== null;
    const total = hasTotal ? Number(stats.total) : null;
    const percent =
      hasTotal && total > 0
        ? Math.min(100, Math.round((imported / total) * 100))
        : null;
    return {
      key,
      label,
      percent,
      importedLabel: imported.toLocaleString(),
      outcomes:
        props.dataImport.source_provider === 'csv'
          ? [
              {
                label: t('DATA_IMPORTS.CSV.CREATED'),
                value: stats.created || 0,
              },
              {
                label: t('DATA_IMPORTS.CSV.UPDATED'),
                value: stats.updated || 0,
              },
              { label: t('DATA_IMPORTS.CSV.FAILED'), value: stats.failed || 0 },
            ]
          : null,
      caption: progressCaption(hasTotal, total),
    };
  });
});

// Fit the grid to the number of groups so no empty cells show.
const columnsClass = computed(() => {
  if (items.value.length >= 3) return 'sm:grid-cols-3';
  if (items.value.length === 2) return 'sm:grid-cols-2';
  return 'sm:grid-cols-1';
});
</script>

<template>
  <section class="overflow-hidden rounded-xl border border-n-weak bg-n-solid-1">
    <h2 class="border-b border-n-weak px-5 py-4 text-heading-3 text-n-slate-12">
      {{ title }}
    </h2>
    <div class="grid grid-cols-1 gap-px bg-n-weak" :class="columnsClass">
      <div
        v-for="item in items"
        :key="item.key"
        class="flex flex-col gap-3 bg-n-solid-1 px-5 py-4"
      >
        <span class="text-label-small text-n-slate-11">{{ item.label }}</span>
        <div class="flex items-end justify-between gap-2">
          <span class="text-heading-1 tabular-nums text-n-slate-12">
            {{ item.importedLabel }}
          </span>
          <span
            v-if="item.percent !== null"
            class="text-label-small tabular-nums text-n-slate-11"
          >
            {{ `${item.percent}%` }}
          </span>
        </div>
        <progress
          v-if="item.percent !== null"
          :value="item.percent"
          max="100"
          :aria-label="item.label"
          class="h-1.5 w-full appearance-none overflow-hidden rounded-full border-0 bg-n-slate-3 [&::-webkit-progress-bar]:rounded-full [&::-webkit-progress-bar]:bg-n-slate-3 [&::-webkit-progress-value]:rounded-full [&::-webkit-progress-value]:bg-n-brand [&::-moz-progress-bar]:bg-n-brand"
        />
        <span class="text-label-small text-n-slate-10">{{ item.caption }}</span>
        <dl
          v-if="item.outcomes"
          class="mt-2 grid grid-cols-3 gap-4 border-t border-n-weak pt-4"
        >
          <div
            v-for="outcome in item.outcomes"
            :key="outcome.label"
            class="flex flex-col gap-1"
          >
            <dt class="text-label-small text-n-slate-11">
              {{ outcome.label }}
            </dt>
            <dd class="text-heading-2 tabular-nums text-n-slate-12">
              {{ outcome.value.toLocaleString() }}
            </dd>
          </div>
        </dl>
      </div>
    </div>
  </section>
</template>
