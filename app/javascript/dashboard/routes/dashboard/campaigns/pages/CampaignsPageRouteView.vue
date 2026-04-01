<script setup>
import { onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';

defineProps({
  keepAlive: { type: Boolean, default: true },
});

const store = useStore();

onMounted(() => {
  store.dispatch('campaigns/get');
  store.dispatch('labels/get');
});
</script>

<template>
  <div
    class="m-0 flex h-full flex-1 flex-col justify-between overflow-auto bg-surface px-6 font-inter text-on-surface antialiased"
  >
    <router-view v-slot="{ Component }">
      <keep-alive v-if="keepAlive">
        <component :is="Component" />
      </keep-alive>
      <component :is="Component" v-else />
    </router-view>
  </div>
</template>
