<script>
import { mapActions, mapGetters } from 'vuex';
import axios from 'axios';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';
import { popoutChatWindow } from '../helpers/popoutHelper';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { useDarkMode } from 'widget/composables/useDarkMode';
import configMixin from 'widget/mixins/configMixin';
import { CONVERSATION_STATUS } from 'shared/constants/messages';
import { tokenHelperInstance } from 'widget/helpers/tokenHelper';

export default {
  name: 'HeaderActions',
  components: { FluentIcon },
  mixins: [configMixin],
  props: {
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
    showEndConversationButton: {
      type: Boolean,
      default: true,
    },
  },
  setup() {
    const { getThemeClass } = useDarkMode();
    return { getThemeClass };
  },
  data() {
    return {
      roomNameSuffix: '',
    };
  },
  computed: {
    ...mapGetters({
      conversationAttributes: 'conversationAttributes/getConversationParams',
      allMessages: 'conversation/getConversation',
      availableAgents: 'agent/availableAgents',
    }),
    canLeaveConversation() {
      return [
        CONVERSATION_STATUS.OPEN,
        CONVERSATION_STATUS.SNOOZED,
        CONVERSATION_STATUS.PENDING,
      ].includes(this.conversationStatus);
    },
    isIframe() {
      return IFrameHelper.isIFrame();
    },
    isRNWebView() {
      return RNHelper.isRNWebView();
    },
    showHeaderActions() {
      return this.isIframe || this.isRNWebView || this.hasWidgetOptions;
    },
    conversationStatus() {
      return this.conversationAttributes.status;
    },
    hasWidgetOptions() {
      return this.showPopoutButton || this.conversationStatus === 'open';
    },
    canConnectToLiveAgent() {
      const allMessages = Object.values(this.allMessages);
      return allMessages.length > 0;
    },
    hasLiveAgentEnabled() {
      return tokenHelperInstance?.hasLiveAgentEnabled;
    },
    isOnline() {
      const allMessages = Object.values(this.allMessages);
      if (this.availableAgents.length && allMessages.length) {
        const receivedMessages = allMessages?.filter(
          message => message.message_type === 1
        );
        if (receivedMessages?.length) {
          const lastMessage = receivedMessages[receivedMessages.length - 1];
          if (!lastMessage || lastMessage?.sender?.type !== 'user') {
            return false;
          }

          const agentId = lastMessage?.sender?.id;
          const agent = this.availableAgents.find(
            availableAgent => availableAgent.id === agentId
          );
          return !!agent;
        }
      }
      return false;
    },
  },
  methods: {
    ...mapActions('conversation', ['sendMessage']),
    popoutWindow() {
      this.closeWindow();
      const {
        location: { origin },
        chatwootWebChannel: { websiteToken },
        authToken,
      } = window;
      popoutChatWindow(
        origin,
        websiteToken,
        this.$root.$i18n.locale,
        authToken
      );
    },
    closeWindow() {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({ event: 'closeWindow' });
      } else if (RNHelper.isRNWebView) {
        RNHelper.sendMessage({ type: 'close-widget' });
      }
    },
    resolveConversation() {
      IFrameHelper.sendMessage({
        event: 'jeeves-connected-to-live-agent',
        connected: false,
      });
      this.$store.dispatch('conversation/resolveConversation');
    },
    async connectToLiveAgent() {
      IFrameHelper.sendMessage({
        event: 'jeeves-connected-to-live-agent',
        connected: true,
      });
      await this.sendMessage({
        content: 'Connect me to a Live Agent',
      });
    },
    async initiateMeeting() {
      this.roomNameSuffix = `${Math.random() * 100}-${Date.now()}`;
      const env = document.location.origin.match(/\.(com|tech)$/)
        ? document.location.origin.split('.').pop()
        : 'tech';

      try {
        const token = await tokenHelperInstance.getToken();

        const allMessages = Object.values(this.allMessages);
        const receivedMessages = allMessages?.filter(
          message =>
            message.message_type === 1 && message.sender?.type === 'user'
        );
        const lastMessage = receivedMessages[receivedMessages.length - 1];
        const agentName = lastMessage?.sender?.name || '';

        const tokens = await axios.post(
          `${tokenHelperInstance.serverUrl}/api/v1/meeting/userAccessToken`,
          {
            user_name: agentName,
            user_email: '',
          },
          { headers: { Authorization: `Bearer ${token}`, 'x-jeeves-space': tokenHelperInstance.space } }
        );

        const response = await axios.post(
          `${tokenHelperInstance.serverUrl}/api/v1/cacheValue`,
          {
            user_token: tokens.data.user_token,
            agent_token: tokens.data.agent_token,
            room: this.roomNameSuffix,
            token,
          },
          { headers: { Authorization: `Bearer ${token}`, 'x-jeeves-space': tokenHelperInstance.space } }
        );

        const baseUrl = tokenHelperInstance.baseUrl;

        const inviteLink = `${baseUrl}/meeting?cacheKey=${response.data}&tenant=${tokenHelperInstance.tenant}&env=${env}&joinee=1`;
        await this.sendMessage({
          content: `Call initiated. Join using: ${inviteLink}`,
        });

        const launchUrl = `${baseUrl}/meeting?cacheKey=${response.data}&tenant=${tokenHelperInstance.tenant}&env=${env}`;

        if (tokenHelperInstance.isEhrLaunch) {
          IFrameHelper.sendMessage({
            event: 'jeevesLaunchInDefaultBrowser',
            url: launchUrl,
          });
        }

        const anchorElm = document.createElement('a');
        anchorElm.href = launchUrl;
        anchorElm.target = '_blank';
        anchorElm.click();
        anchorElm.remove();
      } catch (e) {
        // handle error
      }
    },
  },
};
</script>

<template>
  <div v-if="showHeaderActions" class="actions flex items-center gap-3">
    <button
      v-if="hasLiveAgentEnabled"
      class="button transparent compact"
      title="Connect to Live Agent"
      :disabled="!canConnectToLiveAgent"
      @click="connectToLiveAgent"
    >
      <FluentIcon
        icon="chart-person"
        type="outline"
        size="22"
        :class="getThemeClass('text-black-900', 'dark:text-slate-50')"
      />
    </button>
    <button
      v-if="
        hasLiveAgentEnabled &&
        canLeaveConversation &&
        hasEndConversationEnabled &&
        showEndConversationButton
      "
      class="button transparent compact"
      :disabled="!isOnline"
      title="Start meeting"
      @click="initiateMeeting"
    >
      <FluentIcon
        icon="chat-video"
        type="outline"
        size="22"
        :class="getThemeClass('text-black-900', 'dark:text-slate-50')"
      />
    </button>
    <button
      v-if="
        canLeaveConversation &&
        hasEndConversationEnabled &&
        showEndConversationButton
      "
      class="button transparent compact"
      :title="$t('END_CONVERSATION')"
      @click="resolveConversation"
    >
      <FluentIcon
        icon="sign-out"
        size="22"
        :class="getThemeClass('text-black-900', 'dark:text-slate-50')"
      />
    </button>
    <button
      v-if="showPopoutButton"
      class="button transparent compact new-window--button"
      @click="popoutWindow"
    >
      <FluentIcon
        icon="open"
        size="22"
        :class="getThemeClass('text-black-900', 'dark:text-slate-50')"
      />
    </button>
    <button
      class="button transparent compact close-button"
      :class="{
        'rn-close-button': isRNWebView,
      }"
      @click="closeWindow"
    >
      <FluentIcon
        icon="dismiss"
        size="24"
        :class="getThemeClass('text-black-900', 'dark:text-slate-50')"
      />
    </button>
  </div>
</template>

<style scoped lang="scss">
.actions {
  button {
    @apply ml-2;
  }

  span {
    color: var(--color-heading);
    font-size: 1.125rem; /* equivalent to text-lg if not using Tailwind here */
  }

  .close-button {
    display: none;
  }

  .rn-close-button {
    display: block !important;
  }
}
</style>
