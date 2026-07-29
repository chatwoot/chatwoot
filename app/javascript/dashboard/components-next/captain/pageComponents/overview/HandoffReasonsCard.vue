<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  // Map of reason category -> handoff count for the current window.
  reasons: { type: Object, default: null },
  loading: { type: Boolean, default: false },
});

const { t, te } = useI18n();

const categoryLabel = category => {
  const key = `CAPTAIN.OVERVIEW.HANDOFF_REASONS.CATEGORIES.${category}`;
  return te(key) ? t(key) : category;
};

const rows = computed(() => {
  const entries = Object.entries(props.reasons ?? {});
  const total = entries.reduce((sum, [, count]) => sum + count, 0);
  if (!total) return [];

  return entries
    .sort(([, a], [, b]) => b - a)
    .map(([category, count]) => {
      const share = Math.round((count / total) * 100);
      return {
        category,
        label: categoryLabel(category),
        share,
        display: `${count} · ${share}%`,
      };
    });
});
</script>

<template>
  <div
    class="flex flex-col gap-4 p-5 border rounded-xl bg-n-solid-1 border-n-weak"
  >
    <div class="flex items-center gap-1.5 group">
      <span class="text-sm font-medium text-n-slate-11">
        {{ $t('CAPTAIN.OVERVIEW.HANDOFF_REASONS.TITLE') }}
      </span>
      <span
        v-tooltip="$t('CAPTAIN.OVERVIEW.HANDOFF_REASONS.HINT')"
        class="transition-opacity opacity-0 cursor-help i-lucide-info size-3.5 text-n-slate-10 group-hover:opacity-100"
      />
    </div>

    <div v-if="loading" class="flex flex-col gap-3">
      <div
        v-for="n in 3"
        :key="n"
        class="h-5 rounded bg-n-slate-3 animate-pulse"
      />
    </div>

    <span v-else-if="!rows.length" class="text-sm text-n-slate-10">
      {{ $t('CAPTAIN.OVERVIEW.HANDOFF_REASONS.EMPTY') }}
    </span>

    <div v-else class="flex flex-col gap-3">
      <div
        v-for="row in rows"
        :key="row.category"
        class="grid items-center gap-3 grid-cols-[minmax(0,14rem)_1fr_auto]"
      >
        <span class="text-sm truncate text-n-slate-12">{{ row.label }}</span>
        <div class="h-2 overflow-hidden rounded-full bg-n-slate-3">
          <div
            class="h-full rounded-full bg-n-brand"
            :style="{ width: `${row.share}%` }"
          />
        </div>
        <span class="text-sm font-medium tabular-nums text-n-slate-11">
          {{ row.display }}
        </span>
      </div>
    </div>
  </div>
</template>
