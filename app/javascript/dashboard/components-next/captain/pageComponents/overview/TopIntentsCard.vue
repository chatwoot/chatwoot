<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  // { total_intents, total_questions, intents: [{ question, count, conversations, matched, auto_resolved, handed_off, open }] }
  intents: {
    type: Object,
    default: () => ({ total_intents: 0, total_questions: 0, intents: [] }),
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();

const list = computed(() => props.intents?.intents || []);
const hasData = computed(() => list.value.length > 0);

// Share of questions each intent represents, so the bars are comparable.
const maxCount = computed(() =>
  list.value.reduce((max, intent) => Math.max(max, intent.count), 0)
);

const share = count =>
  maxCount.value === 0 ? 0 : Math.round((count / maxCount.value) * 100);

const resolutionLabel = intent => {
  const total = intent.auto_resolved + intent.handed_off + intent.open;
  if (total === 0) return t('CAPTAIN.OVERVIEW.INTENTS.RESOLUTION.UNKNOWN');
  if (intent.handed_off > 0)
    return t('CAPTAIN.OVERVIEW.INTENTS.RESOLUTION.ESCALATED');
  if (intent.open > 0)
    return t('CAPTAIN.OVERVIEW.INTENTS.RESOLUTION.IN_PROGRESS');
  return t('CAPTAIN.OVERVIEW.INTENTS.RESOLUTION.AUTO_RESOLVED');
};
</script>

<template>
  <div
    class="flex flex-col gap-4 p-5 border rounded-xl bg-n-solid-1 border-n-weak"
  >
    <div class="flex items-center justify-between">
      <span class="text-sm font-medium text-n-slate-12">
        {{ $t('CAPTAIN.OVERVIEW.INTENTS.TITLE') }}
      </span>
      <span v-if="hasData" class="text-xs tabular-nums text-n-slate-11">
        {{
          $t('CAPTAIN.OVERVIEW.INTENTS.COUNT', {
            count: intents.total_questions,
          })
        }}
      </span>
    </div>

    <div
      v-if="loading"
      class="flex flex-col gap-3"
      :aria-label="$t('CAPTAIN.OVERVIEW.INTENTS.LOADING')"
    >
      <div
        v-for="n in 4"
        :key="n"
        class="w-full h-9 rounded bg-n-slate-3 animate-pulse"
      />
    </div>

    <div v-else-if="!hasData" class="py-2 text-sm text-n-slate-11">
      {{ $t('CAPTAIN.OVERVIEW.INTENTS.EMPTY') }}
    </div>

    <ul v-else class="flex flex-col gap-3">
      <li
        v-for="intent in list"
        :key="intent.question"
        class="flex flex-col gap-1.5"
      >
        <div class="flex items-start justify-between gap-3">
          <div class="flex items-center gap-2 min-w-0">
            <span
              class="truncate text-sm text-n-slate-12"
              :title="intent.question"
            >
              {{ intent.question }}
            </span>
            <span
              v-if="!intent.matched"
              class="shrink-0 rounded-full bg-n-amber-3 px-1.5 py-0.5 text-[10px] font-medium text-n-amber-11"
            >
              {{ $t('CAPTAIN.OVERVIEW.INTENTS.NEW') }}
            </span>
          </div>
          <span class="shrink-0 text-xs tabular-nums text-n-slate-11">
            {{ $t('CAPTAIN.OVERVIEW.INTENTS.ASKED', { count: intent.count }) }}
          </span>
        </div>
        <div class="w-full h-1.5 overflow-hidden rounded-full bg-n-alpha-2">
          <div
            class="h-full rounded-full bg-n-brand"
            :style="{ width: `${share(intent.count)}%` }"
          />
        </div>
        <div class="flex items-center gap-2 text-xs text-n-slate-11">
          <span>{{
            $t('CAPTAIN.OVERVIEW.INTENTS.RESOLUTION_LINE', {
              count: intent.conversations,
              resolution: resolutionLabel(intent),
            })
          }}</span>
        </div>
      </li>
    </ul>
  </div>
</template>
