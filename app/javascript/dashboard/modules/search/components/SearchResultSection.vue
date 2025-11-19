<script setup>
import { computed } from 'vue';

import Icon from 'dashboard/components-next/icon/Icon.vue';

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
  <section class="mx-0 mb-3">
    <div
      v-if="showTitle"
      class="sticky top-0 pt-2 py-3 z-50 bg-gradient-to-b from-n-background from-80% to-transparent mb-3 -mx-1.5 px-1.5"
    >
      <h3 class="text-sm text-n-slate-11">{{ title }}</h3>
    </div>
    <slot />
    <woot-loading-state
      v-if="isFetching"
      :message="empty ? $t('SEARCH.SEARCHING_DATA') : $t('SEARCH.LOADING_DATA')"
    />
    <div
      v-if="empty && !isFetching"
      class="flex items-start justify-center px-4 py-6 rounded-xl bg-n-slate-2 dark:bg-n-solid-1"
    >
      <Icon
        icon="i-lucide-info"
        class="text-n-slate-11 size-4 flex-shrink-0 mt-[3px]"
      />
      <p class="mx-2 my-0 text-center text-n-slate-11">
        {{ $t('SEARCH.EMPTY_STATE', { item: titleCase, query }) }}
      </p>
    </div>
  </section>
</template>
