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
      conversationSize: 'conversation/getConversationSize',
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
