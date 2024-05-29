<template>
  <div
    class="flex flex-col justify-between flex-1 h-full m-0 overflow-auto bg-white dark:bg-slate-900"
  >
    <keep-alive v-if="keepAlive">
      <router-view />
    </keep-alive>
    <router-view v-else />
  </div>
</template>

<script setup>
defineProps({
  keepAlive: {
    type: Boolean,
    default: true,
  },
});
</script>
