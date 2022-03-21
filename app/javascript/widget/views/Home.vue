<template>
  <div class="flex flex-1 flex-col justify-end">
    <div class="flex flex-1 overflow-auto">
      <!-- Load Converstion List Components Here -->
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
      currentUser: 'contacts/getCurrentUser',
    }),
  },
  methods: {
    startConversation() {
      const isUserEmailAvailable = !!this.currentUser.email;
      if (this.preChatFormEnabled && !this.conversationSize) {
        return this.replaceRoute('prechat-form', {
          disableContactFields: isUserEmailAvailable,
        });
      }
      return this.replaceRoute('messages');
    },
  },
};
</script>
