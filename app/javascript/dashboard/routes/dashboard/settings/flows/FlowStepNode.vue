<script setup>
import { Handle, Position } from '@vue-flow/core';
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  data: { type: Object, required: true },
  selected: { type: Boolean, default: false },
});

const { t } = useI18n();

const filledButtons = computed(() =>
  (props.data.buttons || []).filter(b => (b.title || '').trim())
);

const displayTitle = computed(() => {
  if ((props.data.title || '').trim()) return props.data.title.trim();
  return props.data.label;
});

const cardClass = computed(() => {
  const base =
    'min-w-[11rem] max-w-[15rem] rounded-md shadow-sm outline outline-1 px-2.5 py-2 bg-n-background dark:bg-n-solid-1';
  if (props.data.brokenBranch) {
    return `${base} outline-n-amber-9 bg-n-amber-2/40 dark:bg-n-solid-amber`;
  }
  if (props.selected) {
    return `${base} outline-n-brand bg-n-blue-2/40 dark:bg-n-solid-blue`;
  }
  return `${base} outline-n-weak`;
});

const onRemove = event => {
  event.stopPropagation();
  props.data.onRemove?.(props.data.stepIndex);
};

const handleStyle = leftPercent => ({
  left: `${leftPercent}%`,
});
</script>

<template>
  <div :class="cardClass">
    <Handle
      id="in"
      type="target"
      :position="Position.Top"
      class="!bg-n-brand !size-2.5 !border-0"
    />

    <div class="flex items-start justify-between gap-2 mb-1">
      <p class="m-0 text-[10px] font-medium text-n-slate-11">
        {{ t('FLOWS.EDIT.STEP_N', { n: data.stepIndex + 1 }) }}
      </p>
      <button
        v-if="data.canRemove"
        type="button"
        class="text-n-ruby-11 hover:text-n-ruby-12 p-0.5 -mt-0.5 -mr-0.5"
        :title="t('FLOWS.EDIT.DELETE_BTN_TOOLTIP')"
        @click="onRemove"
      >
        <span class="i-lucide-trash-2 size-3 block" />
      </button>
    </div>

    <p class="m-0 text-xs font-semibold text-n-slate-12 line-clamp-1">
      {{ displayTitle }}
    </p>

    <div v-if="filledButtons.length" class="mt-2 flex flex-col gap-1.5 pb-3">
      <span
        v-for="(btn, i) in filledButtons"
        :key="i"
        class="text-[11px] leading-tight font-medium text-n-amber-11 bg-n-amber-2 dark:bg-n-solid-amber px-2 py-1.5 rounded truncate w-full text-center"
      >
        {{ btn.title }}
      </span>
    </div>

    <template v-if="filledButtons.length">
      <Handle
        v-for="(btn, i) in filledButtons"
        :id="`btn-${data.buttons.indexOf(btn)}`"
        :key="`btn-${i}`"
        type="source"
        :position="Position.Bottom"
        class="!bg-n-amber-9 !size-2.5 !border-0"
        :style="handleStyle(((i + 1) / (filledButtons.length + 1)) * 100)"
      />
    </template>
    <Handle
      v-else
      id="out"
      type="source"
      :position="Position.Bottom"
      class="!bg-n-brand !size-2.5 !border-0"
    />
  </div>
</template>
