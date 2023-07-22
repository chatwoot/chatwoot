<template>
  <div
    class="flex flex-col brand-bg relative flex-1 mt-1 -mb-1 bg-brand-primary"
  >
    <elevated-sheet
      is-collapsed
      class="flex flex-col absolute top-0 flex-1 w-full z-10 h-full"
    >
      <div class="flex flex-col h-full py-4 bg-white">
        <chat-header
          :avatar-url="channelConfig.avatarUrl"
          :title="channelConfig.websiteName"
          :body="replyWaitMessage"
          show-back-button
          :show-popout-button="appConfig.showPopoutButton"
          @back="onBackButtonClick"
          @popout="onPopoutButtonClick"
        />
        <div class="flex flex-1 overflow-auto pt-4">
          <pre-chat-form :options="preChatFormOptions" @submit="onSubmit" />
        </div>
      </div>
    </elevated-sheet>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ChatHeader from '../components/ChatHeader.vue';
import PreChatForm from '../components/PreChat/Form';
import ElevatedSheet from '../components/ElevatedSheet.vue';

import routerMixin from 'widget/mixins/routerMixin';
import availabilityMixin from 'widget/mixins/availability';
import nextAvailabilityTime from 'widget/mixins/nextAvailabilityTime';
import configMixin from '../mixins/configMixin';
import darkMixin from 'widget/mixins/darkModeMixin.js';

import { isEmptyObject } from 'widget/helpers/utils';
import { popoutChatWindow } from '../helpers/popoutHelper';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';
export default {
  components: {
    PreChatForm,
    ElevatedSheet,
    ChatHeader,
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
      conversationSize: 'conversation/getConversationSize',
      availableAgents: 'agent/availableAgents',
      appConfig: 'appConfig/getAppConfig',
      widgetColor: 'appConfig/getWidgetColor',
    }),
  },
  watch: {
    conversationSize(newSize, oldSize) {
      if (!oldSize && newSize > oldSize) {
        this.replaceRoute('messages');
      }
    },
  },
  methods: {
    onBackButtonClick() {
      this.replaceRoute('home');
    },
    closeWindow() {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({ event: 'closeWindow' });
      } else if (RNHelper.isRNWebView) {
        RNHelper.sendMessage({ type: 'close-widget' });
      }
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
    onSubmit({
      fullName,
      emailAddress,
      message,
      activeCampaignId,
      phoneNumber,
      contactCustomAttributes,
      conversationCustomAttributes,
    }) {
      if (activeCampaignId) {
        bus.$emit('execute-campaign', {
          campaignId: activeCampaignId,
          customAttributes: conversationCustomAttributes,
        });
        this.$store.dispatch('contacts/update', {
          user: {
            email: emailAddress,
            name: fullName,
            phone_number: phoneNumber,
          },
        });
      } else {
        this.$store.dispatch('conversation/createConversation', {
          fullName: fullName,
          emailAddress: emailAddress,
          message: message,
          phoneNumber: phoneNumber,
          customAttributes: conversationCustomAttributes,
        });
      }
      if (!isEmptyObject(contactCustomAttributes)) {
        this.$store.dispatch(
          'contacts/setCustomAttributes',
          contactCustomAttributes
        );
      }
    },
  },
};
</script>
