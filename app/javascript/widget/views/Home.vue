<template>
  <div class="home" @keydown.esc="closeChat">
    <div class="flex flex-col flex-1 overflow-auto">
      <div class="header-wrap bg-white expanded">
        <chat-header-expanded
          :intro-heading="channelConfig.welcomeTitle"
          :intro-body="channelConfig.welcomeTagline"
          :avatar-url="channelConfig.avatarUrl"
          :show-popout-button="showPopoutButton"
        />
      </div>
      <banner />

      <team-availability
        :available-agents="availableAgents"
        @start-conversation="startConversation"
      />

      <div class="px-6 mt-8">
        <h3 class="text-xl font-medium text-gray-900">
          Last conversation
        </h3>
        <conversation-item :conversation="lastActiveConversation" />
        <chat-footer :conversation-id="lastActiveConversationId" />
        <button
          class="mt-2 font-medium text-woot-600 hover:text-woot-500 transition
          ease-in-out duration-150"
          @click="clickAllConversations"
        >
          See all conversations
          <span aria-hidden="true">&rarr;</span>
        </button>
      </div>

      <div class="px-6 mt-8">
        <h3 class="text-xl font-medium text-gray-900">
          FAQ
        </h3>
        <div>
          <h4></h4>
        </div>

        <button
          class="font-medium text-woot-600 hover:text-woot-500 transition
          ease-in-out duration-150"
          @click="clickAllConversations"
        >
          See all conversations
          <span aria-hidden="true">&rarr;</span>
        </button>
      </div>

      <div class="footer-wrap">
        <branding></branding>
      </div>
    </div>
  </div>
</template>

<script>
import Branding from 'shared/components/Branding.vue';
import ChatFooter from 'widget/components/ChatFooter.vue';
import ChatHeaderExpanded from 'widget/components/ChatHeaderExpanded.vue';
import ConversationItem from 'widget/components/ConversationItem';

import { IFrameHelper } from 'widget/helpers/utils';
import configMixin from '../mixins/configMixin';
import TeamAvailability from 'widget/components/TeamAvailability';
import Spinner from 'shared/components/Spinner.vue';
import Banner from 'widget/components/Banner.vue';
import { mapGetters } from 'vuex';
import { BUS_EVENTS } from 'shared/constants/busEvents';

export default {
  name: 'Home',
  components: {
    Branding,
    ChatFooter,
    ChatHeaderExpanded,
    Spinner,
    TeamAvailability,
    ConversationItem,
    Banner,
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
  },
  data() {
    return {
      isOnCollapsedView: false,
      isOnNewConversation: false,
    };
  },
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      conversationAttributes: 'conversationAttributes/getConversationParams',
      getTotalMessageCount: 'conversationV2/allMessagesCountIn',
      getGroupedMessages: 'conversationV2/groupByMessagesIn',
      getIsFetchingList: 'conversationV2/isFetchingConversationsList',
      lastActiveConversationId: 'conversationV2/lastActiveConversationId',
      getConversationById: 'conversationV2/getConversationById',
      getCurrentUser: 'contactV2/getCurrentUser',
    }),
    conversationSize() {
      return this.getTotalMessageCount(this.conversationId);
    },
    groupedMessages() {
      return this.getGroupedMessages(this.conversationId);
    },
    isFetchingList() {
      return this.getIsFetchingList(this.conversationId);
    },
    currentUser() {
      return this.getCurrentUser(this.conversationId);
    },
    lastActiveConversation() {
      const conversationId = this.lastActiveConversationId;
      return this.getConversationById(conversationId);
    },
  },
  mounted() {
    bus.$on(BUS_EVENTS.START_NEW_CONVERSATION, () => {
      this.isOnCollapsedView = true;
      this.isOnNewConversation = true;
    });
  },
  methods: {
    async startConversation() {
      this.isOnCollapsedView = !this.isOnCollapsedView;
      const conversationId = await this.$store.dispatch(
        'conversationV2/createConversation',
        {
          inboxIdentifier: window.chatwootWebChannel.inboxIdentifier,
          contactIdentifier: window.contactIdentifier,
        }
      );

      this.$router.push({
        name: 'chat',
        params: {
          conversationId: conversationId,
        },
      });
    },
    closeChat() {
      IFrameHelper.sendMessage({ event: 'closeChat' });
    },
    clickAllConversations() {
      this.$router.push({
        name: 'conversations',
      });
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
