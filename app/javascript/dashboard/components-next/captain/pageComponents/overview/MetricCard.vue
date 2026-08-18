<script setup>
import { computed } from 'vue';

const props = defineProps({
  label: { type: String, required: true },
  value: { type: String, required: true },
  trend: { type: String, default: '' },
  supportingValue: { type: String, default: '' },
  supportingText: { type: String, default: '' },
  description: { type: String, default: '' },
  valueClass: { type: String, default: 'text-n-slate-12' },
  valueSizeClass: { type: String, default: 'text-3xl' },
  layout: {
    type: String,
    default: 'standard',
    validator: value => ['standard', 'headline'].includes(value),
  },
  showHint: { type: Boolean, default: false },
  compact: { type: Boolean, default: false },
  trendUp: { type: Boolean, default: null },
  hint: { type: String, default: '' },
  // null = neutral, true = good direction, false = bad direction
  trendGood: { type: Boolean, default: null },
  clickable: { type: Boolean, default: false },
  loading: { type: Boolean, default: false },
});

const emit = defineEmits(['click']);

const trendClass = computed(() => {
  if (props.trendGood === null) return 'text-n-slate-11';
  return props.trendGood ? 'text-n-teal-11' : 'text-n-ruby-11';
});

const onActivate = () => {
  if (props.clickable) emit('click');
};
</script>

<template>
  <div
    class="flex flex-col p-5 group bg-n-card"
    :class="[
      layout === 'headline' ? 'justify-between' : compact ? 'gap-2' : 'gap-3',
      clickable
        ? 'cursor-pointer transition-colors hover:bg-n-slate-2/50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand'
        : '',
    ]"
    :role="clickable ? 'button' : undefined"
    :tabindex="clickable ? 0 : undefined"
    @click="onActivate"
    @keydown.enter.self.prevent="onActivate"
    @keydown.space.self.prevent="onActivate"
  >
    <div v-if="layout === 'standard'" class="flex items-start w-full gap-1.5">
      <div
        class="min-w-0 text-sm font-[420] leading-[21px] tracking-[-0.28px] text-n-slate-11"
      >
        <span>{{ label }}</span>
        <span
          v-if="hint"
          v-tooltip="hint"
          class="inline-block ms-1.5 align-[-2px] cursor-help i-lucide-info size-3.5 text-n-slate-11"
          :class="
            showHint
              ? ''
              : 'transition-opacity opacity-0 group-hover:opacity-100'
          "
        />
      </div>
      <span
        v-if="!loading && trend"
        class="flex items-center gap-1 ml-auto text-sm font-medium leading-[21px] tracking-[0.14px] tabular-nums shrink-0"
        :class="trendClass"
      >
        {{ trend }}
        <span
          v-if="trendUp !== null"
          class="size-3"
          :class="[
            trendUp
              ? 'i-fluent-caret-up-12-filled'
              : 'i-fluent-caret-down-12-filled',
          ]"
        />
      </span>
    </div>
    <div
      v-if="layout === 'headline' && !loading"
      class="flex items-start justify-between gap-2"
    >
      <span
        class="font-[520] leading-8 tracking-[-0.48px] tabular-nums"
        :class="[valueSizeClass, valueClass]"
      >
        {{ value }}
      </span>
      <span
        v-if="trend"
        class="flex items-center gap-1 text-sm font-medium leading-[21px] tracking-[0.14px] tabular-nums shrink-0"
        :class="trendClass"
      >
        {{ trend }}
        <span
          v-if="trendUp !== null"
          class="size-[10.5px]"
          :class="[
            trendUp
              ? 'i-fluent-caret-up-12-filled'
              : 'i-fluent-caret-down-12-filled',
          ]"
        />
      </span>
    </div>
    <div
      v-if="layout === 'headline'"
      class="text-sm font-[420] leading-[21px] tracking-[-0.28px] text-n-slate-11"
    >
      <span>{{ label }}</span>
      <span
        v-if="hint"
        v-tooltip="hint"
        class="inline-block ms-1.5 align-[-2px] cursor-help i-lucide-info size-3 text-n-slate-11"
        :class="
          showHint ? '' : 'transition-opacity opacity-0 group-hover:opacity-100'
        "
      />
    </div>
    <div v-if="loading" class="flex items-end justify-between gap-2 mt-auto">
      <div class="w-20 rounded h-9 bg-n-slate-3 animate-pulse" />
      <div class="w-10 h-5 rounded bg-n-slate-3 animate-pulse" />
    </div>
    <div v-else-if="layout === 'standard'" class="flex flex-col min-w-0 gap-1">
      <div class="flex items-baseline justify-between gap-2">
        <span
          class="font-[520] leading-8 tracking-[-0.48px] tabular-nums"
          :class="[valueSizeClass, valueClass]"
        >
          {{ value }}
        </span>
        <span
          v-if="supportingValue || supportingText"
          class="text-sm font-[420] leading-[21px] tracking-[-0.28px] text-right tabular-nums shrink-0"
        >
          <span class="text-n-slate-12">{{ supportingValue }}</span>
          <span class="text-n-slate-10">
            {{ supportingValue && supportingText ? ' ' : ''
            }}{{ supportingText }}
          </span>
        </span>
      </div>
      <span
        v-if="description"
        class="text-sm font-[420] leading-[21px] tracking-[-0.28px] text-n-slate-11"
      >
        {{ description }}
      </span>
    </div>
    <span
      v-if="layout === 'headline' && description"
      class="text-sm font-[420] leading-[21px] tracking-[-0.28px] text-n-slate-11"
    >
      {{ description }}
    </span>
  </div>
</template>
