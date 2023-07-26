<template>
  <div
    class="z-50 rounded-md border-t border-slate-50 w-full"
    :class="!portal ? 'flex flex-1 justify-end' : 'pb-2'"
  >
    <div v-if="portal" class="px-4 py-2 w-full">
      <div class="p-4 rounded-md bg-white dark:bg-slate-700 shadow w-full">
        <article-hero
          v-if="
            !articleUiFlags.isFetching &&
              !articleUiFlags.isError &&
              popularArticles.length
          "
          :articles="popularArticles"
          @view="openArticleInArticleViewer"
          @view-all="viewAllArticles"
        />
        <div
          v-if="articleUiFlags.isFetching"
          class="flex flex-col items-center justify-center py-8"
        >
          <div class="inline-block p-4 rounded-lg bg-slate-200">
            <spinner size="small" />
          </div>
        </div>
      </div>
    </div>
    <div class="px-4 pt-2">
      <team-availability
        :available-agents="availableAgents"
        :has-conversation="!!conversationSize"
        @start-conversation="startConversation"
      />
    </div>
  </div>
</template>

<script>
import TeamAvailability from 'widget/components/TeamAvailability';
import ArticleHero from 'widget/components/ArticleHero';
import Spinner from 'shared/components/Spinner.vue';

import { mapGetters } from 'vuex';
import routerMixin from 'widget/mixins/routerMixin';
import configMixin from 'widget/mixins/configMixin';

export default {
  name: 'Home',
  components: {
    Spinner,
    ArticleHero,
    TeamAvailability,
  },
  mixins: [configMixin, routerMixin],
  props: {
    hasFetched: {
      type: Boolean,
      default: false,
    },
    isCampaignViewClicked: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      activeCampaign: 'campaign/getActiveCampaign',
      conversationSize: 'conversation/getConversationSize',
      popularArticles: 'article/popularArticles',
      articleUiFlags: 'article/uiFlags',
    }),
    portal() {
      return window.chatwootWebChannel.portal;
    },
  },
  mounted() {
    if (this.portal && this.popularArticles.length === 0) {
      this.$store.dispatch('article/fetch', {
        slug: this.portal.slug,
        locale: 'en',
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
      this.$router.push({
        name: 'article-viewer',
        params: { link: `${link}?show_plain_layout=true` },
      });
    },
    viewAllArticles() {
      const {
        portal: { slug },
        locale = 'en',
      } = window.chatwootWebChannel.portal.slug;
      this.openArticleInArticleViewer(`/hc/${slug}/${locale}`);
    },
  },
};
</script>
