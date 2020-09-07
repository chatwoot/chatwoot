<template>
  <div class="home">
    <div class="header-wrap">
      <chat-header-expanded
        v-if="isHeaderExpanded && !hideWelcomeHeader"
        :intro-heading="introHeading"
        :intro-body="introBody"
        :avatar-url="channelConfig.avatarUrl"
        :show-popout-button="showPopoutButton"
      />
      <chat-header
        v-else
        :title="channelConfig.websiteName"
        :avatar-url="channelConfig.avatarUrl"
        :show-popout-button="showPopoutButton"
      />
    </div>
    <conversation-wrap :grouped-messages="groupedMessages" />
    <div class="footer-wrap">
      <div
        v-if="showInputTextArea && !(isHeaderExpanded && !hideWelcomeHeader)"
        class="input-wrap"
      >
        <chat-footer />
      </div>
      <team-availability
        v-if="isHeaderExpanded && !hideWelcomeHeader"
        :available-agents="availableAgents"
      />
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
import configMixin from '../mixins/configMixin';
import TeamAvailability from 'widget/components/TeamAvailability';

export default {
  name: 'Home',
  components: {
    Branding,
    ChatFooter,
    ChatHeader,
    ChatHeaderExpanded,
    ConversationWrap,
    TeamAvailability,
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
    showPopoutButton: {
      type: Boolean,
      default: false,
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
    border-radius: $space-normal $space-normal $space-small $space-small;
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
