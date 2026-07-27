import { defineStore } from 'pinia';
import { ref } from 'vue';
import { fetchArticles, fetchArticle } from 'widget-v2/api/articles';
import { useConfigStore } from './config';

export const useArticlesStore = defineStore('articles', () => {
  const articles = ref([]);
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
    popularArticles,
    activeArticle,
    loading,
    searchQuery,
    search,
    loadPopular,
    open,
  };
});
