<script setup>
defineProps({
  steps: { type: Array, required: true },
  currentIndex: { type: Number, default: 0 },
  progressPercent: { type: Number, default: 0 },
});
</script>

<template>
  <div class="flex flex-col gap-2">
    <!-- Progress bar -->
    <div class="h-1 w-full bg-n-solid-3 rounded-full overflow-hidden">
      <div
        class="h-full bg-n-blue-9 rounded-full transition-all duration-500 ease-out"
        :style="{ width: `${progressPercent}%` }"
      />
    </div>
    <!-- Step labels -->
    <div class="flex items-center justify-between">
      <span
        v-for="(step, idx) in steps"
        :key="idx"
        class="text-[10px] font-medium transition-colors duration-200"
        :class="idx <= currentIndex ? 'text-n-blue-11' : 'text-n-slate-9'"
      >
        {{ step }}
      </span>
    </div>
  </div>
</template>
