<script setup>
import { onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';

const store = useStore();

onMounted(() => {
  store.dispatch('messageTemplates/get');
  store.dispatch('inboxes/get');
});
</script>

<template>
  <div
    class="flex flex-col justify-between flex-1 h-full m-0 overflow-auto bg-n-surface-1"
  >
    <router-view />
  </div>
</template>
