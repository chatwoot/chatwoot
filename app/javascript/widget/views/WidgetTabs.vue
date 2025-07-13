<script setup>
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { computed, defineEmits, defineProps } from 'vue';
import { useDarkMode } from 'widget/composables/useDarkMode';

const { prefersDarkMode } = useDarkMode();
const { t } = useI18n();

const router = useRouter();

const emit = defineEmits(['tabChange']);

const props = defineProps({
  activeTabIndex: {
    type: Number,
    required: true,
  },
});

// REVIEW: Maybe all this logic can simply be shifted to ArticleViewer instead (Also check Article Container which has the same code)

const portal = computed(() => window.chatwootWebChannel.portal);

const locale = computed(() => {
  const { locale: selectedLocale } = t;
  const {
    allowed_locales: allowedLocales,
    default_locale: defaultLocale = 'en',
  } = portal.value.config;
  // IMPORTANT: Variation strict locale matching, Follow iso_639_1_code
  // If the exact match of a locale is available in the list of portal locales, return it
  // Else return the default locale. Eg: `es` will not work if `es_ES` is available in the list
  if (allowedLocales.includes(selectedLocale)) {
    return locale;
  }
  return defaultLocale;
});

const buildArticleViewerParams = link => {
  const params = new URLSearchParams({
    show_plain_layout: 'true',
    theme: prefersDarkMode.value ? 'dark' : 'light',
  });

  // Combine link with query parameters
  const linkToOpen = `${link}?${params.toString()}`;
  // router.push({ name: 'article-viewer', query: { link: linkToOpen } });
  return { link: linkToOpen };
};

const getArticleViewerParams = () => {
  const {
    portal: { slug },
  } = window.chatwootWebChannel;
  return buildArticleViewerParams(`/hc/${slug}/${locale.value}`);
};

const tabList = {
  CONVERSATION: {
    route: 'messages',
    params: {},
  },

  ...(window.chatwootWebChannel.portal !== null
    ? {
        ARTICLES: {
          route: 'article-viewer',
          params: getArticleViewerParams(),
        },
      }
    : {}),
  ...(window.chatwootWebChannel.hasShop
    ? {
        ORDER: {
          route: 'shopify-orders-block',
          params: {},
        },
      }
    : {}),
};

const tabs = computed(() => {
  return Object.entries(tabList).map(([key, info]) => ({
    label: t(`TAB_VIEW.${key}`),
    value: info,
  }));
});

const handleTabChange = info => {
  console.log('Tab change:', info);

  router.replace({ name: info.value.route, query: info.value.params });
  // replaceRoute(info.value.route, info.value.params);
};
</script>

<template>
  <div v-if="tabs.length > 1" class="p-2">
    <TabBar
      :tabs="tabs"
      :initial-active-tab="activeTabIndex"
      :fixed-size="true"
      @tab-changed="handleTabChange"
      class="w-full"
    />
  </div>
</template>
