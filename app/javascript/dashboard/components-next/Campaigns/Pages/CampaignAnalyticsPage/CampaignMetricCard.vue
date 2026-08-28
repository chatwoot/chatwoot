<script setup>
defineProps({
  label: {
    type: String,
    required: true,
  },
  value: {
    type: [String, Number],
    default: 0,
  },
  hint: {
    type: String,
    default: '',
  },
  rate: {
    type: String,
    default: '',
  },
  loading: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div class="flex flex-col gap-3 p-5 group bg-n-solid-1">
    <div class="flex items-center gap-1.5">
      <span class="text-sm font-medium text-n-slate-11">{{ label }}</span>
      <span
        v-if="hint"
        v-tooltip="hint"
        class="transition-opacity opacity-0 cursor-help i-lucide-info size-3.5 text-n-slate-10 group-hover:opacity-100"
      />
    </div>
    <div v-if="loading" class="flex items-end justify-between gap-2">
      <div class="w-20 rounded h-9 bg-n-slate-3 animate-pulse" />
      <div class="w-10 h-5 rounded bg-n-slate-3 animate-pulse" />
    </div>
    <div v-else class="flex items-end justify-between gap-2">
      <span
        class="text-3xl font-semibold tracking-tight tabular-nums text-n-slate-12"
      >
        {{ value }}
      </span>
      <span
        v-if="rate"
        class="text-sm font-medium tabular-nums text-n-slate-11"
      >
        {{ rate }}
      </span>
    </div>
  </div>
</template>
