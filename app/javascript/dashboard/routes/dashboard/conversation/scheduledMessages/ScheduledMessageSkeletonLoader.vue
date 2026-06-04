<script setup>
defineProps({
  rows: {
    type: Number,
    default: 3,
  },
});
</script>

<template>
  <div class="flex flex-col">
    <div
      v-for="n in rows"
      :key="n"
      class="flex flex-col gap-3 px-4 py-3 border-b border-n-strong"
    >
      <div class="flex items-start gap-3">
        <div class="size-10 rounded-full bg-n-slate-3 animate-pulse shrink-0" />

        <div class="flex-1 min-w-0 space-y-1.5">
          <div class="h-4 w-3/5 rounded bg-n-slate-3 animate-pulse" />
          <div class="h-3 w-2/5 rounded bg-n-slate-3 animate-pulse" />
          <div class="h-3 w-1/3 rounded bg-n-slate-3 animate-pulse" />
        </div>

        <div
          class="h-5 w-16 rounded-full bg-n-slate-3 animate-pulse shrink-0"
        />
      </div>

      <div class="space-y-1.5">
        <div class="h-4 w-full rounded bg-n-slate-3 animate-pulse" />
        <div class="h-4 w-4/5 rounded bg-n-slate-3 animate-pulse" />
      </div>
    </div>
  </div>
</template>
