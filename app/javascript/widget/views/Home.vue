<script>
import TeamAvailability from 'widget/components/TeamAvailability.vue';
import { mapGetters } from 'vuex';
import routerMixin from 'widget/mixins/routerMixin';
import configMixin from 'widget/mixins/configMixin';
import ArticleContainer from '../components/pageComponents/Home/Article/ArticleContainer.vue';
import ShopifyOrdersContainer from '../components/pageComponents/Home/ShopifyOrders/ShopifyOrdersContainer.vue';
export default {
  name: 'Home',
  components: {
    ArticleContainer,
    TeamAvailability,
    ShopifyOrdersContainer,
  },
  mixins: [configMixin, routerMixin],
  data() {
    return {
      hasShop: window.chatwootWebChannel.hasShop,
    };
  },
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      conversationSize: 'conversation/getConversationSize',
      unreadMessageCount: 'conversation/getUnreadMessageCount',
    }),
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

<template>
  <div class="z-50 flex flex-col justify-start flex-1 h-full w-full p-4 gap-4">
    <TeamAvailability
      :available-agents="availableAgents"
      :has-conversation="!!conversationSize"
      :unread-count="unreadMessageCount"
      @start-conversation="startConversation"
    />

    <ArticleContainer />
    <ShopifyOrdersContainer v-if="hasShop" :limit="3" :compact="true" />
  </div>
</template>
