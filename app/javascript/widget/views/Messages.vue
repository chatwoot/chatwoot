<template>
  <div class="flex flex-col bg-brand-primary relative flex-1 mt-1 -mb-1">
    <elevated-sheet
      is-collapsed
      is-rounded
      class="flex flex-col absolute top-0 flex-1 h-custom w-full z-10"
    >
      <div class="flex flex-col h-full py-4 flex-1 bg-white">
        <div class="-mx-4">
          <chat-header
            :avatar-url="channelConfig.avatarUrl"
            :title="channelConfig.websiteName"
            :body="replyWaitMessage"
            show-back-button
            :show-popout-button="appConfig.showPopoutButton"
            :show-resolve-button="showResolveButton"
            @back="onBackButtonClick"
            @popout="popoutWindow"
            @resolve="resolveConversation"
          />
        </div>
        <conversation-wrap :grouped-messages="groupedMessages" />
        <chat-footer />
      </div>
    </elevated-sheet>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import ChatHeader from '../components/ChatHeader.vue';
import ChatFooter from '../components/ChatFooter.vue';
import ConversationWrap from '../components/ConversationWrap.vue';

import { popoutChatWindow } from '../helpers/popoutHelper';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';

import routerMixin from 'widget/mixins/routerMixin';
import availabilityMixin from 'widget/mixins/availability';
import nextAvailabilityTime from 'widget/mixins/nextAvailabilityTime';
import configMixin from '../mixins/configMixin';
import darkMixin from 'widget/mixins/darkModeMixin.js';
import ElevatedSheet from '../components/ElevatedSheet.vue';

import { CONVERSATION_STATUS } from 'shared/constants/messages';

export default {
  components: {
    ChatFooter,
    ConversationWrap,
    ChatHeader,
    ElevatedSheet,
  },
  mixins: [
    configMixin,
    availabilityMixin,
    nextAvailabilityTime,
    darkMixin,
    routerMixin,
  ],
  computed: {
    ...mapGetters({
      groupedMessages: 'conversation/getGroupedConversation',
      availableAgents: 'agent/availableAgents',
      appConfig: 'appConfig/getAppConfig',
      widgetColor: 'appConfig/getWidgetColor',
      conversationAttributes: 'conversationAttributes/getConversationParams',
    }),
    canLeaveConversation() {
      return [
        CONVERSATION_STATUS.OPEN,
        CONVERSATION_STATUS.SNOOZED,
        CONVERSATION_STATUS.PENDING,
      ].includes(this.conversationStatus);
    },

    conversationStatus() {
      return this.conversationAttributes.status;
    },
    hasWidgetOptions() {
      return this.showPopoutButton || this.conversationStatus === 'open';
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
    showResolveButton() {
      return this.canLeaveConversation && this.hasEndConversationEnabled;
    },
  },
  mounted() {
    this.$store.dispatch('conversation/setUserLastSeen');
  },
  methods: {
    onBackButtonClick() {
      this.replaceRoute('home');
    },
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
      this.$store.dispatch('conversation/resolveConversation');
    },
  },
};
</script>
<style scoped lang="scss">
.h-custom {
  /* Height of container minus peek a boo height enough to show bottom branding ; */
  height: calc(100% - 0.5rem);
}
</style>
