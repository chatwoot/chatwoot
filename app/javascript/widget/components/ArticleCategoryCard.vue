<template>
  <div class="py-2">
    <h3 class="text-sm font-semibold text-slate-900 mb-0">{{ title }}</h3>
    <article-list :articles="articles" />
    <router-link v-slot="{ href }" custom :to="categoryPath">
      <a
        :href="href"
        class="inline-flex text-sm font-medium rounded-md px-2 py-1 -ml-2 leading-6 text-slate-800 justify-between items-center hover:bg-slate-25 see-articles"
      >
        See all articles
        <span class="px-1 text-slate-700 all-chat-button">
          <fluent-icon icon="arrow-right" size="14" />
        </span>
      </a>
    </router-link>
  </div>
</template>

<script>
import ArticleList from './ArticleList.vue';
export default {
  components: { ArticleList },
  props: {
    title: {
      type: String,
      default: '',
    },
    articles: {
      type: Array,
      default: () => [],
    },
    categoryPath: {
      type: String,
      default: '',
    },
  },
};
</script>
<style lang="scss" scoped>
.see-articles {
  color: var(--brand-textButtonClear);
  svg {
    color: var(--brand-textButtonClear);
  }
}
</style>
