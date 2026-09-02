<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  rows: {
    type: Array,
    default: () => [],
  },
});

const { t } = useI18n();

const maxResolved = computed(() =>
  Math.max(0, ...props.rows.map(row => row.resolvedCount))
);

const getBarPercentage = resolvedCount =>
  maxResolved.value ? (resolvedCount / maxResolved.value) * 100 : 0;

const getBarStyle = resolvedCount => ({
  width: `${getBarPercentage(resolvedCount)}%`,
});

const getBarLabel = row =>
  `${row.name}: ${row.resolvedCount} ${t('OVERVIEW_REPORTS.AGENT_RANKING.RESOLVED')}`;
</script>

<template>
  <div
    class="w-full max-w-full overflow-x-auto rounded-lg border border-n-weak"
  >
    <table
      class="min-w-full border-separate border-spacing-0 text-sm"
      :aria-label="t('OVERVIEW_REPORTS.AGENT_RANKING.ARIA_LABEL')"
    >
      <thead>
        <tr>
          <th
            scope="col"
            class="w-16 border-b border-e border-n-weak bg-n-solid-2 px-3 py-2 text-end font-medium text-n-slate-11"
          >
            {{ t('OVERVIEW_REPORTS.AGENT_RANKING.RANK') }}
          </th>
          <th
            scope="col"
            class="w-full min-w-48 border-b border-e border-n-weak bg-n-solid-2 px-3 py-2 text-start font-medium text-n-slate-11"
          >
            {{ t('OVERVIEW_REPORTS.AGENT_RANKING.AGENT') }}
          </th>
          <th
            scope="col"
            class="min-w-32 border-b border-e border-n-weak bg-n-solid-2 px-3 py-2 text-end font-medium text-n-slate-11"
          >
            {{ t('OVERVIEW_REPORTS.AGENT_RANKING.CONVERSATIONS') }}
          </th>
          <th
            scope="col"
            class="min-w-24 border-b border-e border-n-weak bg-n-solid-2 px-3 py-2 text-end font-medium text-n-slate-11"
          >
            {{ t('OVERVIEW_REPORTS.AGENT_RANKING.RESOLVED') }}
          </th>
          <th
            scope="col"
            class="min-w-48 border-b border-n-weak bg-n-solid-2 px-3 py-2"
          >
            <span class="sr-only">
              {{ t('OVERVIEW_REPORTS.AGENT_RANKING.BAR_LABEL') }}
            </span>
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-if="!rows.length">
          <td colspan="5" class="px-3 py-8 text-center text-n-slate-11">
            {{ t('OVERVIEW_REPORTS.AGENT_RANKING.NO_AGENTS') }}
          </td>
        </tr>
        <template v-else>
          <tr v-for="(row, index) in rows" :key="row.id">
            <th
              scope="row"
              class="border-b border-e border-n-weak px-3 py-2 text-end tabular-nums"
              :class="
                index < 3 ? 'font-semibold text-n-blue-11' : 'text-n-slate-11'
              "
            >
              {{ index + 1 }}
            </th>
            <td
              class="w-full min-w-48 border-b border-e border-n-weak px-3 py-2 text-start font-medium text-n-slate-12"
            >
              {{ row.name }}
            </td>
            <td
              class="border-b border-e border-n-weak px-3 py-2 text-end tabular-nums text-n-slate-12"
            >
              {{ row.conversationsCount }}
            </td>
            <td
              class="border-b border-e border-n-weak px-3 py-2 text-end tabular-nums text-n-slate-12"
            >
              {{ row.resolvedCount }}
            </td>
            <td class="border-b border-n-weak px-3 py-2">
              <div
                class="h-2 w-full overflow-hidden rounded bg-n-slate-3"
                role="img"
                :aria-label="getBarLabel(row)"
              >
                <div
                  data-testid="agent-ranking-bar"
                  class="h-full rounded bg-n-blue-9"
                  :style="getBarStyle(row.resolvedCount)"
                />
              </div>
            </td>
          </tr>
        </template>
      </tbody>
    </table>
  </div>
</template>
