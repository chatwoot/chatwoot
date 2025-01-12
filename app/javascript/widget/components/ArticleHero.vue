<script setup>
import { defineProps, defineEmits } from 'vue';
import ArticleList from './ArticleList.vue';
import { useMapGetter } from 'dashboard/composables/store';

defineProps({
  articles: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['view', 'viewAll']);
const widgetColor = useMapGetter('appConfig/getWidgetColor');

const onArticleClick = link => {
  emit('view', link);
};
</script>

<template>
  <div>
    <h3 class="mb-0 text-sm font-medium text-slate-800 dark:text-slate-50">
      {{ $t('PORTAL.POPULAR_ARTICLES') }}
    </h3>
    <ArticleList :articles="articles" @select-article="onArticleClick" />
    <button
      class="inline-flex items-center justify-between px-2 py-1 -ml-2 text-sm font-medium leading-6 rounded-md text-slate-800 dark:text-slate-50 hover:bg-slate-25 dark:hover:bg-slate-800 see-articles"
      :style="{ color: widgetColor }"
      @click="$emit('viewAll')"
    >
      <span class="pr-2 text-sm">{{ $t('PORTAL.VIEW_ALL_ARTICLES') }}</span>
      <FluentIcon icon="arrow-right" size="14" />
    </button>
  </div>
</template>
