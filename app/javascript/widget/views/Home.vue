<template>
  <div class="home" @keydown.esc="closeChat">
    <div class="flex flex-col flex-1 overflow-auto">
      <chat-header-expanded
        :intro-heading="channelConfig.welcomeTitle"
        :intro-body="channelConfig.welcomeTagline"
        :avatar-url="channelConfig.avatarUrl"
        :show-popout-button="showPopoutButton"
      />
      <banner />
      <active-conversations
        v-if="lastActiveConversationId"
        :conversations="allActiveConversations"
      />
      <team-availability
        :available-agents="availableAgents"
        @start-conversation="startConversation"
      />

      <div class="footer-wrap">
        <branding></branding>
      </div>
    </div>
  </div>
</template>

<script>
import Branding from 'shared/components/Branding';
import ChatHeaderExpanded from 'widget/components/ChatHeaderExpanded';
import ActiveConversations from 'widget/components/ActiveConversations';

import { IFrameHelper } from 'widget/helpers/utils';
import configMixin from '../mixins/configMixin';
import TeamAvailability from 'widget/components/TeamAvailability';
import Banner from 'widget/components/Banner.vue';
import { mapGetters } from 'vuex';

export default {
  name: 'Home',
  components: {
    Banner,
    Branding,
    TeamAvailability,
    ChatHeaderExpanded,
    ActiveConversations,
  },
  mixins: [configMixin],
  props: {
    conversationId: {
      type: Boolean,
      default: false,
    },
    showPopoutButton: {
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
      lastActiveConversationId: 'conversation/lastActiveConversationId',
      allActiveConversations: 'conversation/allActiveConversations',
    }),
  },
  methods: {
    async startConversation() {
      this.$router.push({
        name: 'chat',
        params: {
          conversationId: 0,
        },
      });
    },
    closeChat() {
      IFrameHelper.sendMessage({ event: 'closeChat' });
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables';
@import '~widget/assets/scss/mixins';

.home {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  overflow: hidden;

  .header-wrap {
    border-radius: $space-normal $space-normal 0 0;
    flex-shrink: 0;
    transition: max-height 300ms;
    z-index: 99;

    &.expanded {
      max-height: 16rem;
    }

    &.collapsed {
      max-height: 4.5rem;
    }

    @media only screen and (min-device-width: 320px) and (max-device-width: 667px) {
      border-radius: 0;
    }
  }

  .footer-wrap {
    flex-shrink: 0;
    width: 100%;
    display: flex;
    flex-direction: column;
    position: relative;
  }

  .input-wrap {
    padding: 0 $space-two;
  }
}
</style>
