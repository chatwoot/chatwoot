<script setup>
defineProps({
  badges: {
    type: Array,
    default: () => [],
  },
  emphasized: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div
    v-if="badges.length"
    class="flex flex-wrap gap-1"
    :class="emphasized ? 'mt-1' : ''"
  >
    <span
      v-for="badge in badges"
      :key="badge.key"
      class="inline-flex items-center max-w-full truncate rounded-md px-1.5 py-0.5 text-xxs font-medium"
      :class="
        emphasized
          ? 'bg-n-brand/10 text-n-brand ring-1 ring-inset ring-n-brand/20'
          : 'bg-n-slate-3 text-n-slate-12 dark:bg-n-solid-3'
      "
      :title="`${badge.label}: ${badge.formatted}`"
    >
      <span class="truncate">{{ badge.label }}: {{ badge.formatted }}</span>
    </span>
  </div>
</template>
