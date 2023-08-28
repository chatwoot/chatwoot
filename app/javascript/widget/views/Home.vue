<template>
  <div class="flex flex-1 flex-col justify-end">
    <div class="flex flex-1 overflow-auto">
      <!-- Load Conversation List Components Here -->
    </div>
    <team-availability
      :available-agents="availableAgents"
      :has-conversation="!!conversationSize"
      @start-conversation="startConversation"
    />
  </div>
</template>

<script>
import configMixin from '../mixins/configMixin';
import TeamAvailability from 'widget/components/TeamAvailability';
import { mapGetters } from 'vuex';
import routerMixin from 'widget/mixins/routerMixin';
export default {
  name: 'Home',
  components: {
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
      // conversationSize: 'conversation/getConversationSize',
      messageCountIn: 'conversationV3/allMessagesCountIn',
      activeConversationId: 'conversationV3/lastActiveConversationId',

      popularArticles: 'article/popularArticles',
      articleUiFlags: 'article/uiFlags',
    }),
    portal() {
      return window.chatwootWebChannel.portal;
    },
    showArticles() {
      return (
        this.portal &&
        (this.articleUiFlags.isFetching || this.popularArticles.length)
      );
    },
    conversationSize() {
      return this.messageCountIn(this.activeConversationId);
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
  },
};
</script>
