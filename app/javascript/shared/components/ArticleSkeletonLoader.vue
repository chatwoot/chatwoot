<template>
  <div class="p-6 space-y-6">
    <div class="space-y-2">
      <div class="h-6 bg-slate-100 rounded animate-shimmer w-1/5" />
      <div class="h-10 bg-slate-100 rounded animate-shimmer w-3/5" />
    </div>
    <div class="space-y-2">
      <div class="h-5 bg-slate-100 rounded animate-shimmer" />
      <div class="h-5 bg-slate-100 rounded animate-shimmer" />
      <div class="h-5 bg-slate-100 rounded animate-shimmer" />
    </div>
    <div class="space-y-2">
      <div class="h-5 bg-slate-100 rounded animate-shimmer" />
      <div class="h-5 bg-slate-100 rounded animate-shimmer" />
      <div class="h-5 bg-slate-100 rounded animate-shimmer w-7/10" />
    </div>
  </div>
</template>

<script>
export default {
  name: 'SkeletonLoader',
};
</script>

<style>
@keyframes shimmer {
  0% {
    background-position: -200px 0;
  }
  100% {
    background-position: 200px 0;
  }
}

.animate-shimmer {
  background: linear-gradient(90deg, #f5f5f5 25%, #eeeeee 50%, #f5f5f5 75%);
  background-size: 400px 400px;
  background-position: center center;
  background-repeat: repeat;
  animation: shimmer 2s infinite ease-in;
}
</style>
