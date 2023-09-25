<template>
  <div class="p-4 space-y-6 bg-white dark:bg-slate-900">
    <div class="space-y-2 pulse-animation">
      <div class="h-6 bg-slate-100 dark:bg-slate-700 rounded w-1/5" />
      <div class="h-10 bg-slate-100 dark:bg-slate-700 rounded w-3/5" />
    </div>
    <div class="space-y-2 pulse-animation">
      <div class="h-5 bg-slate-100 dark:bg-slate-700 rounded" />
      <div class="h-5 bg-slate-100 dark:bg-slate-700 rounded" />
      <div class="h-5 bg-slate-100 dark:bg-slate-700 rounded" />
      <div class="h-5 bg-slate-100 dark:bg-slate-700 rounded  w-4/5" />
    </div>
    <div class="space-y-2 pulse-animation">
      <div class="h-5 bg-slate-100 dark:bg-slate-700 rounded" />
      <div class="h-5 bg-slate-100 dark:bg-slate-700 rounded" />
      <div class="h-5 bg-slate-100 dark:bg-slate-700 rounded w-3/5" />
      <div class="h-5 bg-slate-100 dark:bg-slate-700 rounded" />
    </div>
    <div class="space-y-2 pulse-animation">
      <div class="h-5 bg-slate-100 dark:bg-slate-700 rounded" />
      <div class="h-5 bg-slate-100 dark:bg-slate-700 rounded" />
      <div class="h-5 bg-slate-100 dark:bg-slate-700 rounded" />
      <div class="h-5 bg-slate-100 dark:bg-slate-700 rounded w-3/5" />
    </div>
  </div>
</template>
<style scoped>
.pulse-animation {
  animation: pulse 1.5s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}
</style>
