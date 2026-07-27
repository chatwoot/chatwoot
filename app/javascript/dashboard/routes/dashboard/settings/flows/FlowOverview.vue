<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { summarizeSteps } from './flowStepSummary';

const props = defineProps({
  steps: { type: Array, default: () => [] },
  stepTargets: { type: Array, default: () => [] },
  flowActionTypes: { type: Array, default: () => [] },
});

const { t } = useI18n();

const summaries = computed(() =>
  summarizeSteps(props.steps, props.stepTargets, props.flowActionTypes, t)
);
</script>

<template>
  <div class="flex flex-col gap-3">
    <p class="m-0 text-sm text-n-slate-11">
      {{ t('FLOWS.EDIT.OVERVIEW_HINT') }}
    </p>
    <p v-if="!summaries.length" class="m-0 text-sm text-n-slate-11">
      {{ t('FLOWS.EDIT.OVERVIEW_EMPTY') }}
    </p>
    <div
      v-for="item in summaries"
      :key="item.id"
      class="rounded-md border border-n-weak bg-n-solid-1 px-3 py-2"
    >
      <p class="m-0 text-sm font-medium text-n-slate-12">
        {{ item.headline }}
      </p>
      <ol
        class="m-0 mt-1.5 pl-4 text-xs text-n-slate-11 list-decimal space-y-0.5"
      >
        <li v-for="(label, i) in item.actions" :key="`a-${item.id}-${i}`">
          {{ label }}
        </li>
        <li v-if="!item.actions.length">
          {{ t('FLOWS.EDIT.PREVIEW_NO_ACTIONS') }}
        </li>
        <li v-if="item.waiting">
          {{ t('FLOWS.EDIT.STEP_PREVIEW_THEN_WAIT') }}
        </li>
        <li v-for="(line, i) in item.outcomes" :key="`o-${item.id}-${i}`">
          {{ line }}
        </li>
      </ol>
    </div>
  </div>
</template>
