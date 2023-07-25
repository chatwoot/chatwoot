<template>
  <div
    class="flex flex-1 flex-col justify-end sticky top-4 z-50 rounded-md border border-solid border-slate-100 shadow bg-slate-25 w-full"
  >
    <div class="flex flex-1 overflow-auto w-full">
      <div class="px-5 pt-4 pb-2 w-full">
        <article-hero
          v-if="
            !articleUiFlags.isFetching &&
              !articleUiFlags.isError &&
              popularArticles.length
          "
          :articles="popularArticles"
        />
        <div
          v-if="articleUiFlags.isFetching"
          class="flex flex-col items-center justify-center py-8"
        >
          <spinner size="small" class="rounded-lg bg-slate-75" />
        </div>
      </div>
    </div>
    <div
      class="sticky bottom-0 bg-white shadow rounded-md py-4 border border-solid border-slate-50"
    >
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
  data() {
    return {};
  },
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      activeCampaign: 'campaign/getActiveCampaign',
      conversationSize: 'conversation/getConversationSize',
      popularArticles: 'article/popularArticles',
      articleUiFlags: 'article/uiFlags',
    }),
  },
  mounted() {
    const { portal } = window.chatwootWebChannel;
    if (portal) {
      this.$store.dispatch('article/fetch', {
        slug: portal.slug,
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
  },
};
</script>
