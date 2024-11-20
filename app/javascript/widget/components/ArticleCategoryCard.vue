<script>
import { mapGetters } from 'vuex';
import ArticleList from './ArticleList.vue';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

export default {
  components: { FluentIcon, ArticleList },
  props: {
    title: {
      type: String,
      default: '',
    },
    articles: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['view', 'viewAll'],
  computed: {
    ...mapGetters({ widgetColor: 'appConfig/getWidgetColor' }),
  },
  methods: {
    onArticleClick(link) {
      this.$emit('view', link);
    },
  },
};
</script>

<template>
  <div>
    <h3 class="mb-0 text-sm font-medium text-slate-800 dark:text-slate-50">
      {{ title }}
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

<style lang="scss" scoped>
.see-articles {
  color: var(--brand-textButtonClear);
  svg {
    color: var(--brand-textButtonClear);
  }
}
</style>
