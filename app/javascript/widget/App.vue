<template>
  <div
    v-if="!conversationSize && isFetchingList"
    class="flex flex-1 items-center h-full bg-black-25 justify-center"
  >
    <spinner size="" />
  </div>
  <div
    v-else
    class="flex flex-col justify-end h-full"
    :class="{
      'is-mobile': isMobile,
      'is-widget-right': isRightAligned,
      'is-bubble-hidden': hideMessageBubble,
      'is-flat-design': isWidgetStyleFlat,
    }"
  >
    <router-view></router-view>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import { setHeader } from 'widget/helpers/axios';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';
import configMixin from './mixins/configMixin';
import availabilityMixin from 'widget/mixins/availability';
import { getLocale } from './helpers/urlParamsHelper';
import { isEmptyObject } from 'widget/helpers/utils';
import Spinner from 'shared/components/Spinner.vue';
import routerMixin from './mixins/routerMixin';
import {
  getExtraSpaceToScroll,
  loadedEventConfig,
} from './helpers/IframeEventHelper';
import {
  ON_AGENT_MESSAGE_RECEIVED,
  ON_CAMPAIGN_MESSAGE_CLICK,
  ON_UNREAD_MESSAGE_CLICK,
} from './constants/widgetBusEvents';
export default {
  name: 'App',
  components: {
    Spinner,
  },
  mixins: [availabilityMixin, configMixin, routerMixin],
  data() {
    return {
      isMobile: false,
    };
  },
  computed: {
    ...mapGetters({
      activeCampaign: 'campaign/getActiveCampaign',
      campaigns: 'campaign/getCampaigns',
      conversationSize: 'conversation/getConversationSize',
      currentUser: 'contacts/getCurrentUser',
      hasFetched: 'agent/getHasFetched',
      hideMessageBubble: 'appConfig/getHideMessageBubble',
      isFetchingList: 'conversation/getIsFetchingList',
      isRightAligned: 'appConfig/isRightAligned',
      isWidgetOpen: 'appConfig/getIsWidgetOpen',
      messageCount: 'conversation/getMessageCount',
      unreadMessageCount: 'conversation/getUnreadMessageCount',
      isWidgetStyleFlat: 'appConfig/isWidgetStyleFlat',
    }),
    isIFrame() {
      return IFrameHelper.isIFrame();
    },
    isRNWebView() {
      return RNHelper.isRNWebView();
    },
  },
  watch: {
    activeCampaign() {
      this.setCampaignView();
    },
  },
  mounted() {
    const { websiteToken, locale, widgetColor } = window.chatwootWebChannel;
    this.setLocale(locale);
    this.setWidgetColor(widgetColor);
    if (this.isIFrame) {
      this.registerListeners();
      this.sendLoadedEvent();
      setHeader('X-Auth-Token', window.authToken);
    } else {
      setHeader('X-Auth-Token', window.authToken);
      this.fetchOldConversations();
      this.fetchAvailableAgents(websiteToken);
      this.setLocale(getLocale(window.location.search));
    }
    if (this.isRNWebView) {
      this.registerListeners();
      this.sendRNWebViewLoadedEvent();
    }
    this.$store.dispatch('conversationAttributes/getAttributes');
    this.registerUnreadEvents();
    this.registerCampaignEvents();
  },
  methods: {
    ...mapActions('appConfig', [
      'setAppConfig',
      'setReferrerHost',
      'setWidgetColor',
    ]),
    ...mapActions('conversation', ['fetchOldConversations', 'setUserLastSeen']),
    ...mapActions('campaign', [
      'initCampaigns',
      'executeCampaign',
      'resetCampaign',
    ]),
    ...mapActions('agent', ['fetchAvailableAgents']),
    scrollConversationToBottom() {
      const container = this.$el.querySelector('.conversation-wrap');
      container.scrollTop = container.scrollHeight;
    },
    setBubbleLabel() {
      IFrameHelper.sendMessage({
        event: 'setBubbleLabel',
        label: this.$t('BUBBLE.LABEL'),
      });
    },
    setIframeHeight(isFixedHeight) {
      this.$nextTick(() => {
        const extraHeight = getExtraSpaceToScroll();
        IFrameHelper.sendMessage({
          event: 'updateIframeHeight',
          isFixedHeight,
          extraHeight,
        });
      });
    },
    setLocale(locale) {
      const { enabledLanguages } = window.chatwootWebChannel;
      if (enabledLanguages.some(lang => lang.iso_639_1_code === locale)) {
        this.$root.$i18n.locale = locale;
      }
    },
    registerUnreadEvents() {
      bus.$on(ON_AGENT_MESSAGE_RECEIVED, () => {
        const { name: routeName } = this.$route;
        if (this.isWidgetOpen && routeName === 'messages') {
          this.$store.dispatch('conversation/setUserLastSeen');
        }
        this.setUnreadView();
      });
      bus.$on(ON_UNREAD_MESSAGE_CLICK, () => {
        this.replaceRoute('messages').then(() => this.unsetUnreadView());
      });
    },
    registerCampaignEvents() {
      bus.$on(ON_CAMPAIGN_MESSAGE_CLICK, () => {
        if (this.shouldShowPreChatForm) {
          this.replaceRoute('prechat-form');
        } else {
          this.replaceRoute('messages');
          bus.$emit('execute-campaign', { campaignId: this.activeCampaign.id });
        }
        this.unsetUnreadView();
      });
      bus.$on('execute-campaign', campaignDetails => {
        const { customAttributes, campaignId } = campaignDetails;
        const { websiteToken } = window.chatwootWebChannel;
        this.executeCampaign({ campaignId, websiteToken, customAttributes });
        this.replaceRoute('messages');
      });
    },
    setCampaignView() {
      const { messageCount, activeCampaign } = this;
      const isCampaignReadyToExecute =
        !isEmptyObject(activeCampaign) && !messageCount;
      if (this.isIFrame && isCampaignReadyToExecute) {
        this.replaceRoute('campaigns').then(() => {
          this.setIframeHeight(true);
          IFrameHelper.sendMessage({ event: 'setUnreadMode' });
        });
      }
    },
    setUnreadView() {
      const { unreadMessageCount } = this;

      if (this.isIFrame && unreadMessageCount > 0 && !this.isWidgetOpen) {
        this.replaceRoute('unread-messages').then(() => {
          this.setIframeHeight(true);
          IFrameHelper.sendMessage({ event: 'setUnreadMode' });
        });
        this.handleUnreadNotificationDot();
      }
    },
    unsetUnreadView() {
      if (this.isIFrame) {
        IFrameHelper.sendMessage({ event: 'resetUnreadMode' });
        this.setIframeHeight(false);
        this.handleUnreadNotificationDot();
      }
    },
    handleUnreadNotificationDot() {
      const { unreadMessageCount } = this;
      if (this.isIFrame) {
        IFrameHelper.sendMessage({
          event: 'handleNotificationDot',
          unreadMessageCount,
        });
      }
    },
    createWidgetEvents(message) {
      const { eventName } = message;
      const isWidgetTriggerEvent = eventName === 'webwidget.triggered';
      if (
        isWidgetTriggerEvent &&
        ['unread-messages', 'campaigns'].includes(this.$route.name)
      ) {
        return;
      }
      this.$store.dispatch('events/create', { name: eventName });
    },
    registerListeners() {
      const { websiteToken } = window.chatwootWebChannel;
      window.addEventListener('message', e => {
        if (!IFrameHelper.isAValidEvent(e)) {
          return;
        }
        const message = IFrameHelper.getMessage(e);
        if (message.event === 'config-set') {
          this.setLocale(message.locale);
          this.setBubbleLabel();
          this.fetchOldConversations().then(() => this.setUnreadView());
          this.fetchAvailableAgents(websiteToken);
          this.setAppConfig(message);
          this.$store.dispatch('contacts/get');
        } else if (message.event === 'widget-visible') {
          this.scrollConversationToBottom();
        } else if (message.event === 'change-url') {
          const { referrerURL, referrerHost } = message;
          this.initCampaigns({
            currentURL: referrerURL,
            websiteToken,
            isInBusinessHours: this.isInBusinessHours,
          });
          window.referrerURL = referrerURL;
          this.setReferrerHost(referrerHost);
        } else if (message.event === 'toggle-close-button') {
          this.isMobile = message.isMobile;
        } else if (message.event === 'push-event') {
          this.createWidgetEvents(message);
        } else if (message.event === 'set-label') {
          this.$store.dispatch('conversationLabels/create', message.label);
        } else if (message.event === 'remove-label') {
          this.$store.dispatch('conversationLabels/destroy', message.label);
        } else if (message.event === 'set-user') {
          this.$store.dispatch('contacts/update', message);
        } else if (message.event === 'set-custom-attributes') {
          this.$store.dispatch(
            'contacts/setCustomAttributes',
            message.customAttributes
          );
        } else if (message.event === 'delete-custom-attribute') {
          this.$store.dispatch(
            'contacts/deleteCustomAttribute',
            message.customAttribute
          );
        } else if (message.event === 'set-locale') {
          this.setLocale(message.locale);
          this.setBubbleLabel();
        } else if (message.event === 'toggle-open') {
          this.$store.dispatch('appConfig/toggleWidgetOpen', message.isOpen);

          const shouldShowMessageView =
            ['home'].includes(this.$route.name) &&
            message.isOpen &&
            this.messageCount;
          const shouldShowHomeView =
            !message.isOpen &&
            ['unread-messages', 'campaigns'].includes(this.$route.name);

          if (shouldShowMessageView) {
            this.replaceRoute('messages');
          }
          if (shouldShowHomeView) {
            this.$store.dispatch('conversation/setUserLastSeen');
            this.unsetUnreadView();
            this.replaceRoute('home');
          }
          if (!message.isOpen) {
            this.resetCampaign();
          }
        }
      });
    },
    sendLoadedEvent() {
      IFrameHelper.sendMessage(loadedEventConfig());
    },
    sendRNWebViewLoadedEvent() {
      RNHelper.sendMessage(loadedEventConfig());
    },
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/woot.scss';
</style>
