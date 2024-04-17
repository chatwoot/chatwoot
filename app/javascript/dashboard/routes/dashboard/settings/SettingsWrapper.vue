<script setup>
defineProps({
  keepAlive: {
    type: Boolean,
    default: true,
  },
});
</script>

<template>
  <div
    class="flex flex-col w-full h-full px-5 pt-8 pb-3 m-0 overflow-auto bg-white sm:px-16 sm:pt-16 dark:bg-slate-900"
  >
    <div class="flex items-start max-w-[900px] w-full">
      <keep-alive v-if="keepAlive">
        <router-view />
      </keep-alive>
      <router-view v-else />
    </div>
  </div>
</template>
