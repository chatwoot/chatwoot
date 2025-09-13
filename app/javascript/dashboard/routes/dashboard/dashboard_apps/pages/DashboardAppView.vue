<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import IframeLoader from 'shared/components/IframeLoader.vue';

const route = useRoute();
const store = useStore();

const appId = computed(() => Number(route.params.id));
const appData = computed(
  () =>
    store.getters['dashboardApps/getRecords'].find(a => a.id === appId.value) ||
    {}
);

const url = computed(() => appData.value.content?.[0]?.url || '');
</script>

<template>
  <div class="flex flex-1 h-full overflow-hidden">
    <IframeLoader :url="url" class="w-full" />
  </div>
</template>
