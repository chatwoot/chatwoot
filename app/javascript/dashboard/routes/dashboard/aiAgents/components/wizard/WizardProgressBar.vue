<script setup>
defineProps({
  steps: { type: Array, required: true },
  currentIndex: { type: Number, default: 0 },
  progressPercent: { type: Number, default: 0 },
});
</script>

<template>
  <div class="flex flex-col gap-2">
    <!-- Step dots with connecting lines -->
    <div class="flex items-center">
      <template v-for="(step, idx) in steps" :key="idx">
        <!-- Step dot -->
        <div
          class="relative flex items-center justify-center shrink-0 size-7 rounded-full text-[11px] font-semibold transition-all duration-300 select-none"
          :class="[
            idx < currentIndex
              ? 'bg-n-blue-9 text-white'
              : idx === currentIndex
                ? 'bg-n-blue-9 text-white ring-2 ring-n-blue-4 ring-offset-1 ring-offset-n-solid-1'
                : 'bg-n-solid-3 text-n-slate-9',
          ]"
          :title="step"
        >
          <span
            v-if="idx < currentIndex"
            class="i-lucide-check size-3.5"
          />
          <span v-else>{{ idx + 1 }}</span>
        </div>
        <!-- Connector line -->
        <div
          v-if="idx < steps.length - 1"
          class="flex-1 h-[2px] mx-0.5 rounded-full transition-colors duration-300"
          :class="
            idx < currentIndex ? 'bg-n-blue-9' : 'bg-n-solid-3'
          "
        />
      </template>
    </div>
    <!-- Current step label -->
    <p class="text-xs text-center font-medium text-n-blue-11">
      {{ steps[currentIndex] }}
    </p>
  </div>
</template>
