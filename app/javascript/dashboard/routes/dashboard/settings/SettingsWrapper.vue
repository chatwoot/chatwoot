<script setup>
defineProps({
  keepAlive: {
    type: Boolean,
    default: true,
  },
  fullWidth: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div
    class="flex flex-col w-full h-full m-0 overflow-auto bg-n-surface-1 font-inter"
    :class="fullWidth ? 'p-4 sm:p-6' : 'p-6 sm:py-8 lg:px-16'"
  >
    <div
      class="flex items-start w-full"
      :class="fullWidth ? 'max-w-none' : 'max-w-6xl mx-auto'"
    >
      <router-view v-slot="{ Component }">
        <keep-alive v-if="keepAlive">
          <component :is="Component" />
        </keep-alive>
        <component :is="Component" v-else />
      </router-view>
    </div>
  </div>
</template>
