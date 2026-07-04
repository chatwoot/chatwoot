<script setup>
import { computed, toRef } from 'vue';
import { useCrmConversationStage } from 'dashboard/routes/dashboard/crm/composables/useCrmConversationStages';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const STAGE_FALLBACK_COLOR = '#64748b';

const stage = useCrmConversationStage(toRef(props, 'conversationId'));

const dotStyle = computed(() => ({
  backgroundColor: stage.value?.stage_color || STAGE_FALLBACK_COLOR,
}));

const label = computed(() => {
  if (!stage.value?.stage_name) return '';
  return stage.value.multiple_pipelines && stage.value.pipeline_name
    ? `${stage.value.pipeline_name} · ${stage.value.stage_name}`
    : stage.value.stage_name;
});
</script>

<template>
  <div
    v-if="label"
    data-crm-stage-chip
    :title="label"
    class="flex flex-shrink-0 items-center gap-1 rounded-md border border-n-weak bg-n-alpha-1 px-1.5 py-0.5"
  >
    <span class="size-1.5 flex-shrink-0 rounded-full" :style="dotStyle" />
    <span class="max-w-[13rem] truncate text-xs text-n-slate-11">{{
      label
    }}</span>
  </div>
</template>
