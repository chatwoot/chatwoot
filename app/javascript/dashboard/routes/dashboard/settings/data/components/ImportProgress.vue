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
    const imported = Number(stats.imported || 0);
    const hasTotal = Object.prototype.hasOwnProperty.call(stats, 'total');
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
      caption: hasTotal
        ? t('DATA_IMPORTS.DETAIL.PROGRESS_OF_TOTAL', {
            total: total.toLocaleString(),
          })
        : t('DATA_IMPORTS.DETAIL.PROGRESS_IMPORTED'),
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
    <h2 class="border-b border-n-weak px-4 py-3 text-heading-3 text-n-slate-12">
      {{ title }}
    </h2>
    <div class="grid grid-cols-1 gap-px bg-n-weak" :class="columnsClass">
      <div
        v-for="item in items"
        :key="item.key"
        class="flex flex-col gap-2 bg-n-solid-1 px-4 py-3"
      >
        <span class="text-label-small text-n-slate-11">{{ item.label }}</span>
        <div class="flex items-end justify-between gap-2">
          <span
            class="text-xl font-semibold tracking-tight tabular-nums text-n-slate-12"
          >
            {{ item.importedLabel }}
          </span>
          <span
            v-if="item.percent !== null"
            class="text-label-small tabular-nums text-n-slate-11"
          >
            {{ `${item.percent}%` }}
          </span>
        </div>
        <div
          v-if="item.percent !== null"
          class="h-1.5 w-full overflow-hidden rounded-full bg-n-alpha-2"
        >
          <div
            class="h-full rounded-full bg-n-brand transition-all duration-500"
            :style="{ width: `${item.percent}%` }"
          />
        </div>
        <span class="text-label-small text-n-slate-10">{{ item.caption }}</span>
      </div>
    </div>
  </section>
</template>
