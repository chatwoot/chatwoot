<template>
  <div class="flex-1 overflow-auto p-4">
    <header class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-slate-800 dark:text-slate-100">
        {{ $t('INSIGHTS.HEADER') }}
      </h1>
      <!-- Add New Button Placeholder -->
    </header>
    
    <div class="bg-white dark:bg-slate-900 rounded-lg shadow p-6">
      <p class="text-slate-600 dark:text-slate-300">
        {{ $t('INSIGHTS.EMPTY_STATE') }}
      </p>
    </div>
  </div>
</template>

<script>
import { useStore } from 'vuex';
import { onMounted } from 'vue';

export default {
  setup() {
    const store = useStore();

    onMounted(() => {
      store.dispatch('insights/get');
    });

    return {};
  },
};
</script>
