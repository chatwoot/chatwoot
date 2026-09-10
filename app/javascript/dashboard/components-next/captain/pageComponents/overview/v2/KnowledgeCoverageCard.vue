<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import OverviewPanel from './OverviewPanel.vue';
import ProgressMetric from './ProgressMetric.vue';

const props = defineProps({
  knowledge: { type: Object, default: null },
  loading: { type: Boolean, default: false },
});

const emit = defineEmits(['review']);
const { t } = useI18n();

const approved = computed(() => Number(props.knowledge?.approved || 0));
const suggestions = computed(() => Number(props.knowledge?.suggestions || 0));
const total = computed(() => approved.value + suggestions.value);
const coverage = computed(() => Number(props.knowledge?.coverage || 0));

const stats = computed(() => [
  {
    key: 'approved',
    label: t('CAPTAIN.OVERVIEW.KNOWLEDGE.APPROVED'),
    value: approved.value,
  },
  {
    key: 'suggestions',
    label: t('CAPTAIN.OVERVIEW.KNOWLEDGE.SUGGESTIONS'),
    value: suggestions.value,
  },
]);
</script>

<template>
  <OverviewPanel :title="$t('CAPTAIN.OVERVIEW.KNOWLEDGE.TITLE')">
    <template #actions>
      <Button
        sm
        slate
        outline
        :label="$t('CAPTAIN.OVERVIEW.V2.KNOWLEDGE.REVIEW')"
        @click="emit('review')"
      />
    </template>
    <div class="flex flex-col gap-5 p-5">
      <ProgressMetric
        :label="$t('CAPTAIN.OVERVIEW.KNOWLEDGE.TITLE')"
        :used="approved"
        :total="total"
        :usage-label="
          $t('CAPTAIN.OVERVIEW.KNOWLEDGE.COVERAGE', { pct: coverage })
        "
        :value-label="
          $t('CAPTAIN.OVERVIEW.V2.USAGE.VALUE', {
            used: approved.toLocaleString(),
            total: total.toLocaleString(),
          })
        "
        color="rgb(var(--blue-9))"
        :loading="loading"
      />
      <div class="grid grid-cols-2 gap-4">
        <div v-for="stat in stats" :key="stat.key" class="flex flex-col gap-1">
          <span class="text-xs text-n-slate-11">{{ stat.label }}</span>
          <span class="text-2xl font-medium tabular-nums text-n-slate-12">
            {{ stat.value.toLocaleString() }}
          </span>
        </div>
      </div>
    </div>
  </OverviewPanel>
</template>
