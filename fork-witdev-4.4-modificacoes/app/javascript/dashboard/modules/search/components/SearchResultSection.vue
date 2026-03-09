<script setup>
import { computed } from 'vue';

const props = defineProps({
  title: {
    type: String,
    default: '',
  },
  empty: {
    type: Boolean,
    default: false,
  },
  query: {
    type: String,
    default: '',
  },
  showTitle: {
    type: Boolean,
    default: true,
  },
  isFetching: {
    type: Boolean,
    default: true,
  },
});

const titleCase = computed(() => props.title.toLowerCase());
</script>

<template>
  <section class="mx-0 my-2">
    <div v-if="showTitle" class="sticky top-0 p-2 z-50 mb-0.5 bg-n-background">
      <h3 class="text-sm text-n-slate-12">{{ title }}</h3>
    </div>
    <slot />
    <woot-loading-state
      v-if="isFetching"
      :message="empty ? $t('SEARCH.SEARCHING_DATA') : $t('SEARCH.LOADING_DATA')"
    />
    <div
      v-if="empty && !isFetching"
      class="flex items-center justify-center px-4 py-6 m-2 rounded-xl bg-n-slate-2 dark:bg-n-solid-1"
    >
      <fluent-icon icon="info" size="16px" class="text-n-slate-11" />
      <p class="mx-2 my-0 text-center text-n-slate-11">
        {{ $t('SEARCH.EMPTY_STATE', { item: titleCase, query }) }}
      </p>
    </div>
  </section>
</template>
