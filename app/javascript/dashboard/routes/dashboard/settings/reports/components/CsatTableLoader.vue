<script setup>
defineProps({
  rows: {
    type: Number,
    default: 5,
  },
});
</script>

<template>
  <div class="p-6">
    <div class="space-y-4">
      <div class="flex gap-4 pb-3 border-b border-n-weak">
        <div class="h-4 w-32 rounded bg-n-slate-3 animate-pulse" />
        <div class="h-4 w-28 rounded bg-n-slate-3 animate-pulse" />
        <div class="h-4 w-20 rounded bg-n-slate-3 animate-pulse" />
        <div class="h-4 flex-1 rounded bg-n-slate-3 animate-pulse" />
        <div class="h-4 w-20 rounded bg-n-slate-3 animate-pulse" />
      </div>

      <div v-for="n in rows" :key="n" class="flex items-center gap-4 py-3">
        <div class="flex items-center gap-2 w-48">
          <div class="size-8 rounded-full bg-n-slate-3 animate-pulse" />
          <div class="h-4 w-24 rounded bg-n-slate-3 animate-pulse" />
        </div>
        <div class="flex items-center gap-2 w-44">
          <div class="size-8 rounded-full bg-n-slate-3 animate-pulse" />
          <div class="h-4 w-20 rounded bg-n-slate-3 animate-pulse" />
        </div>
        <div class="h-7 w-24 rounded-lg bg-n-slate-3 animate-pulse" />
        <div class="h-4 flex-1 rounded bg-n-slate-3 animate-pulse" />
        <div class="h-4 w-16 rounded bg-n-slate-3 animate-pulse" />
      </div>
    </div>
  </div>
</template>
