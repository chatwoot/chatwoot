<script lang="ts" setup>
import { defineAsyncComponent } from 'vue'
import SearchLoading from './SearchLoading.vue'

const SearchPane = defineAsyncComponent({
  loader: () => import('./SearchPane.vue'),
  loadingComponent: SearchLoading,
  delay: 0,
})

defineProps({
  shown: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits({
  close: () => true,
})

function close() {
  emit('close')
}
</script>

<template>
  <div
    v-show="shown"
    class="histoire-search-modal htw-fixed htw-inset-0 htw-bg-white/80 dark:htw-bg-gray-900/80 htw-z-20"
    data-test-id="search-modal"
  >
    <div
      class="htw-absolute htw-inset-0"
      @click="close()"
    />
    <div class="htw-bg-white dark:htw-bg-gray-900 md:htw-mt-16 md:htw-mx-auto htw-w-screen htw-max-w-[512px] htw-shadow-xl htw-border htw-border-gray-200 dark:htw-border-gray-750 htw-rounded-lg htw-relative htw-divide-y htw-divide-gray-200 dark:htw-divide-gray-850">
      <SearchPane
        :shown="shown"
        @close="close()"
      />
    </div>
  </div>
</template>
