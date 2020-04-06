<template>
  <div class="home">
    <div class="header-wrap">
      <ChatHeaderExpanded v-if="isHeaderExpanded" />
      <ChatHeader v-else :title="getHeaderName" />
    </div>
    <AvailableAgents v-if="showAvailableAgents" :agents="availableAgents" />
    <ConversationWrap :grouped-messages="groupedMessages" />
    <div class="footer-wrap">
      <div class="input-wrap">
        <ChatFooter />
      </div>
      <branding></branding>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import Branding from 'widget/components/Branding.vue';
import ChatFooter from 'widget/components/ChatFooter.vue';
import ChatHeaderExpanded from 'widget/components/ChatHeaderExpanded.vue';
import ChatHeader from 'widget/components/ChatHeader.vue';
import ConversationWrap from 'widget/components/ConversationWrap.vue';
import AvailableAgents from 'widget/components/AvailableAgents.vue';

export default {
  name: 'Home',
  components: {
    ChatFooter,
    ChatHeaderExpanded,
    ConversationWrap,
    ChatHeader,
    Branding,
    AvailableAgents,
  },
  computed: {
    ...mapGetters({
      groupedMessages: 'conversation/getGroupedConversation',
      conversationSize: 'conversation/getConversationSize',
      availableAgents: 'agent/availableAgents',
      hasFetched: 'agent/uiFlags/hasFetched',
    }),
    isHeaderExpanded() {
      return this.conversationSize === 0;
    },
    getHeaderName() {
      return window.chatwootWebChannel.website_name;
    },
    showAvailableAgents() {
      return this.availableAgents.length > 0 && this.conversationSize < 1;
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/woot.scss';

.home {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  background: $color-background;

  .header-wrap {
    flex-shrink: 0;
    border-radius: $space-normal;
    background: white;
    z-index: 99;
    @include shadow-large;

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

    &:before {
      content: '';
      position: absolute;
      top: -$space-normal;
      left: 0;
      width: 100%;
      height: $space-normal;
      opacity: 0.1;
      background: linear-gradient(
        to top,
        $color-background,
        rgba($color-background, 0)
      );
    }
  }

  .input-wrap {
    padding: 0 $space-normal;
  }
}
</style>
