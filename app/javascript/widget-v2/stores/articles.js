import { defineStore } from 'pinia';
import { computed, ref } from 'vue';
import {
  fetchArticles,
  fetchArticle,
  fetchCategories,
} from 'widget-v2/api/articles';
import { useConfigStore } from './config';

export const useArticlesStore = defineStore('articles', () => {
  const articles = ref([]);
  const categories = ref([]);
  const popularArticles = ref([]);
  const activeArticle = ref(null);
  const loading = ref(false);
  const searchQuery = ref('');

  const portalParams = () => {
    const configStore = useConfigStore();
    if (!configStore.portal) return null;
    return {
      slug: configStore.portal.slug,
      locale: configStore.portal.default_locale || 'en',
    };
  };

  // Category payloads carry no id; slugs are the join key with articles.
  const groupedArticles = computed(() => {
    const bySlug = {};
    articles.value.forEach(article => {
      const slug = article.category?.slug || 'uncategorized';
      bySlug[slug] = bySlug[slug] || [];
      bySlug[slug].push(article);
    });

    const sections = [...categories.value]
      .sort((a, b) => (a.position || 0) - (b.position || 0))
      .map(category => ({ category, articles: bySlug[category.slug] || [] }))
      .filter(section => section.articles.length);

    if (bySlug.uncategorized?.length) {
      sections.push({ category: null, articles: bySlug.uncategorized });
    }
    return sections;
  });

  const search = async query => {
    const portal = portalParams();
    if (!portal) return;
    searchQuery.value = query;
    loading.value = true;
    try {
      const { payload } = await fetchArticles({ ...portal, query });
      articles.value = payload;
    } finally {
      loading.value = false;
    }
  };

  const loadCategories = async () => {
    const portal = portalParams();
    if (!portal || categories.value.length) return;
    const { payload } = await fetchCategories(portal);
    categories.value = payload;
  };

  const loadPopular = async () => {
    const portal = portalParams();
    if (!portal || popularArticles.value.length) return;
    const { payload } = await fetchArticles({ ...portal, sort: 'views' });
    popularArticles.value = payload.slice(0, 4);
  };

  const open = async articleSlug => {
    const portal = portalParams();
    if (!portal) return;
    loading.value = true;
    activeArticle.value = null;
    try {
      // The article show endpoint renders the article at the JSON root.
      activeArticle.value = await fetchArticle({
        slug: portal.slug,
        articleSlug,
      });
    } finally {
      loading.value = false;
    }
  };

  return {
    articles,
    categories,
    groupedArticles,
    popularArticles,
    activeArticle,
    loading,
    searchQuery,
    search,
    loadCategories,
    loadPopular,
    open,
  };
});
