<template>
  <div
    v-if="!conversationSize && isFetchingList"
    class="flex flex-1 items-center h-full bg-black-25 justify-center"
  >
    <spinner size="" />
  </div>
  <div v-else class="home">
    <div
      class="header-wrap bg-white"
      :class="{ expanded: !isHeaderCollapsed, collapsed: isHeaderCollapsed }"
    >
      <transition
        enter-active-class="transition-all delay-200 duration-300 ease"
        leave-active-class="transition-all duration-200 ease-in"
        enter-class="opacity-0 transform"
        enter-to-class="opacity-100 transform"
        leave-class="opacity-100 transform"
        leave-to-class="opacity-0 transform"
      >
        <chat-header-expanded
          v-if="!isHeaderCollapsed"
          :intro-heading="channelConfig.welcomeTitle"
          :intro-body="channelConfig.welcomeTagline"
          :avatar-url="channelConfig.avatarUrl"
          :show-popout-button="showPopoutButton"
        />
        <chat-header
          v-if="isHeaderCollapsed"
          :title="channelConfig.websiteName"
          :avatar-url="channelConfig.avatarUrl"
          :show-popout-button="showPopoutButton"
          :available-agents="availableAgents"
        />
      </transition>
    </div>
    <banner />
    <div class="flex flex-1 overflow-auto">
      <conversation-wrap
        v-if="currentView === 'messageView'"
        :grouped-messages="groupedMessages"
      />
      <pre-chat-form
        v-if="currentView === 'preChatFormView'"
        :options="preChatFormOptions"
      />
    </div>
    <div class="footer-wrap">
      <transition
        enter-active-class="transition-all delay-300 duration-300 ease"
        leave-active-class="transition-all duration-200 ease-in"
        enter-class="opacity-0 transform"
        enter-to-class="opacity-100 transform translate-y-0"
        leave-class="opacity-100 transform translate-y-0"
        leave-to-class="opacity-0 transform "
      >
        <div v-if="currentView === 'messageView'" class="input-wrap">
          <chat-footer />
        </div>
        <team-availability
          v-if="currentView === 'cardView'"
          :available-agents="availableAgents"
          @start-conversation="startConversation"
        />
      </transition>
      <branding></branding>
    </div>
  </div>
</template>

<script>
import Branding from 'shared/components/Branding.vue';
import ChatFooter from 'widget/components/ChatFooter.vue';
import ChatHeaderExpanded from 'widget/components/ChatHeaderExpanded.vue';
import ChatHeader from 'widget/components/ChatHeader.vue';
import ConversationWrap from 'widget/components/ConversationWrap.vue';
import configMixin from '../mixins/configMixin';
import TeamAvailability from 'widget/components/TeamAvailability';
import Spinner from 'shared/components/Spinner.vue';
import Banner from 'widget/components/Banner.vue';
import { mapGetters } from 'vuex';
import { MAXIMUM_FILE_UPLOAD_SIZE } from 'shared/constants/messages';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import PreChatForm from '../components/PreChat/Form';
export default {
  name: 'Home',
  components: {
    Branding,
    ChatFooter,
    ChatHeader,
    ChatHeaderExpanded,
    ConversationWrap,
    PreChatForm,
    Spinner,
    TeamAvailability,
    Banner,
  },
  mixins: [configMixin],
  props: {
    hasFetched: {
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
      conversationSize: 'conversation/getConversationSize',
      groupedMessages: 'conversation/getGroupedConversation',
      isFetchingList: 'conversation/getIsFetchingList',
      currentUser: 'contacts/getCurrentUser',
    }),
    currentView() {
      const { email: currentUserEmail = '' } = this.currentUser;
      if (this.isHeaderCollapsed) {
        if (this.conversationSize) {
          return 'messageView';
        }
        if (
          this.isOnNewConversation ||
          (this.preChatFormEnabled && !currentUserEmail)
        ) {
          return 'preChatFormView';
        }
        return 'messageView';
      }
      return 'cardView';
    },
    isOpen() {
      return this.conversationAttributes.status === 'open';
    },
    fileUploadSizeLimit() {
      return MAXIMUM_FILE_UPLOAD_SIZE;
    },
    isHeaderCollapsed() {
      if (!this.hasIntroText || this.conversationSize) {
        return true;
      }

      return this.isOnCollapsedView;
    },
    hasIntroText() {
      return (
        this.channelConfig.welcomeTitle || this.channelConfig.welcomeTagline
      );
    },
  },
  mounted() {
    bus.$on(BUS_EVENTS.START_NEW_CONVERSATION, () => {
      this.isOnCollapsedView = true;
      this.isOnNewConversation = true;
    });
  },
  methods: {
    startConversation() {
      this.isOnCollapsedView = !this.isOnCollapsedView;
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
  background: $color-background;

  .header-wrap {
    border-radius: $space-normal $space-normal 0 0;
    flex-shrink: 0;
    transition: max-height 300ms;
    z-index: 99;
    @include shadow-large;

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
