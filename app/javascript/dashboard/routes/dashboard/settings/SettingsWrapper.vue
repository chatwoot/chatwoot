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
    class="flex flex-col w-full h-full m-0 px-8 lg:px-16 py-8 overflow-auto bg-white dark:bg-slate-900"
  >
    <div class="flex items-start w-full max-w-6xl mx-auto">
      <keep-alive v-if="keepAlive">
        <router-view />
      </keep-alive>
      <router-view v-else />
    </div>
  </div>
</template>
