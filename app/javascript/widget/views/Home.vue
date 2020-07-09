<template>
  <div class="home">
    <div class="header-wrap"
    :style="{ background: widgetColor }">
      <ChatHeaderExpanded
        v-if="isHeaderExpanded && !hideWelcomeHeader"
        :intro-heading="introHeading"
        :intro-body="introBody"
        :avatar-url="channelConfig.avatarUrl"
      />
      <ChatHeader
        v-else
        :title="channelConfig.websiteName"
        :avatar-url="channelConfig.avatarUrl"
      />
    </div>
    <AvailableAgents v-if="showAvailableAgents" :agents="availableAgents" />
    <ConversationWrap :grouped-messages="groupedMessages" />
    <div class="footer-wrap">
      <div v-if="showInputTextArea" class="input-wrap">
        <ChatFooter />
      </div>
      <branding></branding>
    </div>
  </div>
</template>

<script>
import Branding from 'widget/components/Branding.vue';
import ChatFooter from 'widget/components/ChatFooter.vue';
import ChatHeaderExpanded from 'widget/components/ChatHeaderExpanded.vue';
import ChatHeader from 'widget/components/ChatHeader.vue';
import ConversationWrap from 'widget/components/ConversationWrap.vue';
import AvailableAgents from 'widget/components/AvailableAgents.vue';
import configMixin from '../mixins/configMixin';

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
  mixins: [configMixin],
  props: {
    groupedMessages: {
      type: Array,
      default: () => [],
    },
    conversationSize: {
      type: Number,
      default: 0,
    },
    availableAgents: {
      type: Array,
      default: () => [],
    },
    hasFetched: {
      type: Boolean,
      default: false,
    },
    conversationAttributes: {
      type: Object,
      default: () => {},
    },
    unreadMessageCount: {
      type: Number,
      default: 0,
    },
  },
  computed: {
    isOpen() {
      return this.conversationAttributes.status === 'open';
    },
    showInputTextArea() {
      if (this.hideInputForBotConversations) {
        if (this.isOpen) {
          return true;
        }
        return false;
      }
      return true;
    },
    isHeaderExpanded() {
      return this.conversationSize === 0;
    },
    showAvailableAgents() {
      return this.availableAgents.length > 0 && this.conversationSize < 1;
    },
    introHeading() {
      return this.channelConfig.welcomeTitle;
    },
    introBody() {
      return this.channelConfig.welcomeTagline;
    },
    hideWelcomeHeader() {
      return !(this.introHeading || this.introBody);
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
    border-radius: 0;
    background: white;
    background-image: linear-gradient(125deg, rgba(0, 0, 0, 0.05) -10%, rgba(0, 0, 0, 0.55) 100%);
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
