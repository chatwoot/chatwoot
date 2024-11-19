<script>
import TeamAvailability from 'widget/components/TeamAvailability.vue';
import ArticleHero from 'widget/components/ArticleHero.vue';
import ArticleCardSkeletonLoader from 'widget/components/ArticleCardSkeletonLoader.vue';

import { mapGetters } from 'vuex';
import { useDarkMode } from 'widget/composables/useDarkMode';
import routerMixin from 'widget/mixins/routerMixin';
import configMixin from 'widget/mixins/configMixin';

export default {
  name: 'Home',
  components: {
    ArticleHero,
    TeamAvailability,
    ArticleCardSkeletonLoader,
  },
  mixins: [configMixin, routerMixin],
  setup() {
    const { prefersDarkMode } = useDarkMode();
    return { prefersDarkMode };
  },
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      conversationSize: 'conversation/getConversationSize',
      unreadMessageCount: 'conversation/getUnreadMessageCount',
      popularArticles: 'article/popularArticles',
      articleUiFlags: 'article/uiFlags',
    }),
    widgetLocale() {
      return this.$i18n.locale || 'en';
    },
    portal() {
      return window.chatwootWebChannel.portal;
    },
    showArticles() {
      return (
        this.portal &&
        !this.articleUiFlags.isFetching &&
        this.popularArticles.length
      );
    },
    defaultLocale() {
      const widgetLocale = this.widgetLocale;
      const { allowed_locales: allowedLocales, default_locale: defaultLocale } =
        this.portal.config;

      // IMPORTANT: Variation strict locale matching, Follow iso_639_1_code
      // If the exact match of a locale is available in the list of portal locales, return it
      // Else return the default locale. Eg: `es` will not work if `es_ES` is available in the list
      if (allowedLocales.includes(widgetLocale)) {
        return widgetLocale;
      }
      return defaultLocale;
    },
  },
  mounted() {
    if (this.portal && this.popularArticles.length === 0) {
      const locale = this.defaultLocale;
      this.$store.dispatch('article/fetch', {
        slug: this.portal.slug,
        locale,
      });
    }
  },
  methods: {
    startConversation() {
      if (this.preChatFormEnabled && !this.conversationSize) {
        return this.replaceRoute('prechat-form');
      }
      return this.replaceRoute('messages');
    },
    openArticleInArticleViewer(link) {
      let linkToOpen = `${link}?show_plain_layout=true`;
      const isDark = this.prefersDarkMode;
      if (isDark) {
        linkToOpen = `${linkToOpen}&theme=dark`;
      }
      this.$router.push({
        name: 'article-viewer',
        query: { link: linkToOpen },
      });
    },
    viewAllArticles() {
      const locale = this.defaultLocale;
      const {
        portal: { slug },
      } = window.chatwootWebChannel;
      this.openArticleInArticleViewer(`/hc/${slug}/${locale}`);
    },
  },
};
</script>

<template>
  <div
    class="z-50 flex flex-col flex-1 w-full rounded-md"
    :class="{ 'pb-2': showArticles, 'justify-end': !showArticles }"
  >
    <div class="w-full px-4 pt-4">
      <TeamAvailability
        :available-agents="availableAgents"
        :has-conversation="!!conversationSize"
        :unread-count="unreadMessageCount"
        @start-conversation="startConversation"
      />
    </div>
    <div v-if="showArticles" class="w-full px-4 py-2">
      <div class="w-full p-4 bg-white rounded-md shadow-sm dark:bg-slate-700">
        <ArticleHero
          v-if="
            !articleUiFlags.isFetching &&
            !articleUiFlags.isError &&
            popularArticles.length
          "
          :articles="popularArticles"
          @view="openArticleInArticleViewer"
          @view-all="viewAllArticles"
        />
      </div>
    </div>
    <div v-if="articleUiFlags.isFetching" class="w-full px-4 py-2">
      <div class="w-full p-4 bg-white rounded-md shadow-sm dark:bg-slate-700">
        <ArticleCardSkeletonLoader />
      </div>
    </div>
  </div>
</template>
