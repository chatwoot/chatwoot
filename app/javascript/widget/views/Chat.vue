<template>
  <div
    v-if="!conversationSize && isFetchingList"
    class="flex flex-1 items-center h-full bg-black-25 justify-center"
  >
    <spinner size="" />
  </div>
  <div v-else class="home" @keydown.esc="closeChat">
    <div class="header-wrap bg-white  collapsed">
      <chat-header
        :title="channelConfig.websiteName"
        :avatar-url="channelConfig.avatarUrl"
        :show-popout-button="showPopoutButton"
        :available-agents="availableAgents"
      />
    </div>
    <banner />
    <div class="flex flex-1 overflow-auto">
      <conversation-wrap
        v-if="currentView === 'messageView'"
        :grouped-messages="groupedMessages"
      />
    </div>
    <div class="footer-wrap">
      <div class="input-wrap">
        <chat-footer :conversation-id="conversationId" />
      </div>
      <branding></branding>
    </div>
  </div>
</template>

<script>
import Branding from 'shared/components/Branding.vue';
import ChatFooter from 'widget/components/ChatFooter.vue';
import ChatHeader from 'widget/components/ChatHeader.vue';
import ConversationWrap from 'widget/components/ConversationWrap.vue';
import { IFrameHelper } from 'widget/helpers/utils';
import configMixin from '../mixins/configMixin';
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

    ConversationWrap,
    PreChatForm,
    Spinner,
    Banner,
  },
  mixins: [configMixin],
  props: {
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
      currentUser: 'contactV2/getCurrentUser',
      getTotalMessageCount: 'conversationV2/allMessagesCountIn',
      getGroupedMessages: 'conversationV2/groupByMessagesIn',
      getIsFetchingList: 'conversationV2/isFetchingMessages',
    }),
    conversationId() {
      const { conversationId } = this.$route.params;
      return conversationId;
    },
    conversationSize() {
      return this.getTotalMessageCount(this.conversationId);
    },
    groupedMessages() {
      return this.getGroupedMessages(this.conversationId);
    },
    isFetchingList() {
      return this.getIsFetchingList(this.conversationId);
    },
    currentView() {
      const { email: currentUserEmail = '' } = this.currentUser;

      if (this.conversationSize) return 'messageView';

      const shouldShowPreChatForm =
        this.isOnNewConversation ||
        (this.preChatFormEnabled && !currentUserEmail);

      if (shouldShowPreChatForm) return 'preChatFormView';
      return 'messageView';
    },
    isOpen() {
      return this.conversationAttributes.status === 'open';
    },
    fileUploadSizeLimit() {
      return MAXIMUM_FILE_UPLOAD_SIZE;
    },
  },
  mounted() {
    bus.$on(BUS_EVENTS.START_NEW_CONVERSATION, () => {
      this.isOnCollapsedView = true;
      this.isOnNewConversation = true;
    });

    this.$store.dispatch('conversationV2/fetchConversationById', {
      conversationId: this.conversationId,
      inboxIdentifier: window.chatwootWebChannel.inboxIdentifier,
      contactIdentifier: window.contactIdentifier,
    });
  },
  methods: {
    startConversation() {
      this.isOnCollapsedView = !this.isOnCollapsedView;
      this.$store.dispatch('conversationV2/createConversation', {
        inboxIdentifier: window.chatwootWebChannel.inboxIdentifier,
        contactIdentifier: window.contactIdentifier,
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
  background: $color-background;

  .header-wrap {
    border-radius: $space-normal $space-normal 0 0;
    flex-shrink: 0;
    transition: max-height 300ms;
    max-height: 4.5rem;
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
    padding: 0 $space-two;
  }
}
</style>
