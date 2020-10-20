<template>
  <div
    v-if="!conversationSize && isFetchingList"
    class="flex flex-1 items-center h-full bg-black-25 justify-center"
  >
    <spinner size=""></spinner>
  </div>
  <div v-else class="home">
    <div class="header-wrap">
      <transition
        enter-active-class="transition-all delay-200 duration-300 ease"
        leave-active-class="transition-all duration-200 ease-in"
        enter-class="opacity-0 transform -translate-y-32"
        enter-to-class="opacity-100 transform translate-y-0"
        leave-class="opacity-100 transform translate-y-0"
        leave-to-class="opacity-0 transform -translate-y-32"
      >
        <chat-header-expanded
          v-if="!isOnMessageView"
          :intro-heading="introHeading"
          :intro-body="introBody"
          :avatar-url="channelConfig.avatarUrl"
          :show-popout-button="showPopoutButton"
        />
        <chat-header
          v-if="isOnMessageView"
          :title="channelConfig.websiteName"
          :avatar-url="channelConfig.avatarUrl"
          :show-popout-button="showPopoutButton"
          :available-agents="availableAgents"
        />
      </transition>
    </div>
    <conversation-wrap :grouped-messages="groupedMessages" />
    <div class="footer-wrap">
      <transition
        enter-active-class="transition-all delay-300 duration-300 ease"
        leave-active-class="transition-all duration-200 ease-in"
        enter-class="opacity-0 transform translate-y-32"
        enter-to-class="opacity-100 transform translate-y-0"
        leave-class="opacity-100 transform translate-y-0"
        leave-to-class="opacity-0 transform translate-y-32 "
      >
        <div v-if="showInputTextArea && isOnMessageView" class="input-wrap">
          <chat-footer />
        </div>
        <team-availability
          v-if="!isOnMessageView"
          :available-agents="availableAgents"
          @start-conversation="startConversation"
        />
      </transition>
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
import Spinner from 'shared/components/Spinner.vue';
import { mapGetters } from 'vuex';

export default {
  name: 'Home',
  components: {
    Branding,
    ChatFooter,
    ChatHeader,
    ChatHeaderExpanded,
    ConversationWrap,
    Spinner,
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
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      showMessageView: false,
    };
  },
  computed: {
    ...mapGetters({
      isFetchingList: 'conversation/getIsFetchingList',
    }),
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
    isOnMessageView() {
      if (this.hideWelcomeHeader) {
        return true;
      }
      if (this.conversationSize === 0) {
        return this.showMessageView;
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
  methods: {
    startConversation() {
      this.showMessageView = !this.showMessageView;
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables';

.home {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  overflow: hidden;
  background: $color-background;

  .header-wrap {
    flex-shrink: 0;
    border-radius: $space-normal $space-normal $space-small $space-small;
    z-index: 99;

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
