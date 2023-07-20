<template>
  <header
    class="flex justify-between items-center w-full pb-4 border-b border-slate-50"
    :class="$dm('bg-white', 'dark:bg-slate-900')"
  >
    <div class="flex-grow flex items-center flex-shrink-0">
      <button
        v-if="false"
        class="inline-flex h-10 w-8 -ml-2 mr-1 rounded items-center justify-center text-slate-700 hover:bg-slate-25"
        @click="$emit('back')"
      >
        <fluent-icon icon="chevron-left" size="16" />
      </button>
      <img
        v-if="avatarUrl && false"
        class="h-8 w-8 rounded-full mr-3"
        :src="avatarUrl"
        alt="avatar"
      />
      <div
        v-else
        class="h-10 w-10 rounded-md brand-avatar inline-flex justify-center items-center mr-2 flex-shrink-0 font-bold"
      >
        C
      </div>
      <div>
        <h4
          class="font-semibold text-sm leading-4 flex items-center"
          :class="$dm('text-slate-900', 'dark:text-slate-50')"
        >
          <span v-dompurify-html="title" class="mr-1" />
          <div
            :class="
              `h-2 w-2 rounded-full
              ${isOnline ? 'bg-green-500' : 'hidden'}`
            "
          />
        </h4>
        <p
          class="text-xs mt-1 leading-3"
          :class="$dm('text-slate-700', 'dark:text-slate-400')"
        >
          {{ replyWaitMessage }}
        </p>
      </div>
    </div>
    <header-actions
      v-if="showHeaderActions"
      :show-popout-button="showPopoutButton"
      @popout="popoutWindow"
    />
  </header>
</template>

<script>
import { mapGetters } from 'vuex';

import HeaderActions from './HeaderActions';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';
import { popoutChatWindow } from '../helpers/popoutHelper';

import availabilityMixin from 'widget/mixins/availability';
import nextAvailabilityTime from 'widget/mixins/nextAvailabilityTime';
import routerMixin from 'widget/mixins/routerMixin';
import darkMixin from 'widget/mixins/darkModeMixin.js';

import { CONVERSATION_STATUS } from 'shared/constants/messages';

export default {
  name: 'ChatHeader',
  components: {
    FluentIcon,
    HeaderActions,
  },
  mixins: [nextAvailabilityTime, availabilityMixin, routerMixin, darkMixin],
  props: {
    avatarUrl: {
      type: String,
      default: '',
    },
    title: {
      type: String,
      default: '',
    },
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
    showBackButton: {
      type: Boolean,
      default: false,
    },
    availableAgents: {
      type: Array,
      default: () => {},
    },
  },

  computed: {
    ...mapGetters({
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
    isOnline() {
      const { workingHoursEnabled } = this.channelConfig;
      const anyAgentOnline = this.availableAgents.length > 0;

      if (workingHoursEnabled) {
        return this.isInBetweenTheWorkingHours;
      }
      return anyAgentOnline;
    },
  },
  methods: {
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
  },
};
</script>
<style scoped>
.brand-avatar {
  background: var(--brand-bgLight);
  color: var(--brand-bgDark);
}
</style>
