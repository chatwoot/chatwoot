<script setup>
import { useRoute } from 'vue-router';

defineProps({
  keepAlive: {
    type: Boolean,
    default: true,
  },
});

const route = useRoute();
</script>

<template>
  <div
    class="flex flex-col w-full h-full m-0 pb-8 pt-4 px-6 overflow-auto bg-n-surface-1"
  >
    <div class="flex items-start w-full max-w-5xl mx-auto">
      <router-view v-slot="{ Component }">
        <keep-alive v-if="keepAlive">
          <component :is="Component" :key="route.fullPath" />
        </keep-alive>
        <component :is="Component" v-else :key="route.fullPath" />
      </router-view>
    </div>
  </div>
</template>
