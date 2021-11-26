<template>
  <router
    :show-unread-view="showUnreadView"
    :show-campaign-view="showCampaignView"
    :is-mobile="isMobile"
    :has-fetched="hasFetched"
    :unread-message-count="unreadMessageCount"
    :is-left-aligned="isLeftAligned"
    :hide-message-bubble="hideMessageBubble"
    :show-popout-button="showPopoutButton"
    :is-campaign-view-clicked="isCampaignViewClicked"
  />
</template>

<script>
import { mapGetters, mapActions, mapMutations } from 'vuex';
import { setHeader } from 'widget/helpers/axios';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';
import configMixin from './mixins/configMixin';
import availabilityMixin from 'widget/mixins/availability';
import Router from './views/Router';
import { getLocale } from './helpers/urlParamsHelper';
import { isEmptyObject } from 'widget/helpers/utils';
import {
  getExtraSpaceToScroll,
  loadedEventConfig,
} from './helpers/IframeEventHelper';
export default {
  name: 'App',
  components: {
    Router,
  },
  mixins: [availabilityMixin, configMixin],
  data() {
    return {
      showUnreadView: false,
      showCampaignView: false,
      isMobile: false,
      hideMessageBubble: false,
      widgetPosition: 'right',
      showPopoutButton: false,
      isWebWidgetTriggered: false,
      isCampaignViewClicked: false,
      isWidgetOpen: false,
    };
  },
  computed: {
    ...mapGetters({
      hasFetched: 'agent/getHasFetched',
      messageCount: 'conversation/getMessageCount',
      unreadMessageCount: 'conversation/getUnreadMessageCount',
      campaigns: 'campaign/getCampaigns',
      activeCampaign: 'campaign/getActiveCampaign',
    }),
    isLeftAligned() {
      const isLeft = this.widgetPosition === 'left';
      return isLeft;
    },
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
    showUnreadView(newVal) {
      if (newVal) {
        this.setIframeHeight(this.isMobile);
      }
    },
    showCampaignView(newVal) {
      if (newVal) {
        this.setIframeHeight(this.isMobile);
      }
    },
  },
  mounted() {
    const { websiteToken, locale } = window.chatwootWebChannel;
    this.setLocale(locale);
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
    this.setWidgetColor(window.chatwootWebChannel);
    this.registerUnreadEvents();
    this.registerCampaignEvents();
  },
  methods: {
    ...mapActions('appConfig', ['setWidgetColor', 'setReferrerHost']),
    ...mapActions('conversation', ['fetchOldConversations', 'setUserLastSeen']),
    ...mapActions('campaign', [
      'initCampaigns',
      'executeCampaign',
      'resetCampaign',
    ]),
    ...mapActions('agent', ['fetchAvailableAgents']),
    ...mapMutations('events', ['toggleOpen']),
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
    setPosition(position) {
      const widgetPosition = position || 'right';
      this.widgetPosition = widgetPosition;
    },
    setHideMessageBubble(hideBubble) {
      this.hideMessageBubble = !!hideBubble;
    },
    registerUnreadEvents() {
      bus.$on('on-agent-message-received', () => {
        if (!this.isIFrame || this.isWidgetOpen) {
          this.setUserLastSeen();
        }
        this.setUnreadView();
      });
      bus.$on('on-unread-view-clicked', () => {
        this.unsetUnreadView();
        this.setUserLastSeen();
      });
    },
    registerCampaignEvents() {
      bus.$on('on-campaign-view-clicked', () => {
        this.isCampaignViewClicked = true;
        this.showCampaignView = false;
        this.showUnreadView = false;
        this.unsetUnreadView();
        this.setUserLastSeen();
        // Execute campaign only if pre-chat form (and require email too) is not enabled
        if (
          !(this.preChatFormEnabled && this.preChatFormOptions.requireEmail)
        ) {
          bus.$emit('execute-campaign', this.activeCampaign.id);
        }
      });
      bus.$on('execute-campaign', campaignId => {
        const { websiteToken } = window.chatwootWebChannel;
        this.executeCampaign({ campaignId, websiteToken });
      });
    },

    setPopoutDisplay(showPopoutButton) {
      this.showPopoutButton = showPopoutButton;
    },
    setCampaignView() {
      const { messageCount, activeCampaign } = this;
      const isCampaignReadyToExecute =
        !isEmptyObject(activeCampaign) &&
        !messageCount &&
        !this.isWebWidgetTriggered;
      if (this.isIFrame && isCampaignReadyToExecute) {
        this.showCampaignView = true;
        IFrameHelper.sendMessage({
          event: 'setCampaignMode',
        });
        this.setIframeHeight(this.isMobile);
      }
    },
    setUnreadView() {
      const { unreadMessageCount } = this;
      if (this.isIFrame && unreadMessageCount > 0) {
        IFrameHelper.sendMessage({
          event: 'setUnreadMode',
          unreadMessageCount,
        });
        this.setIframeHeight(this.isMobile);
        this.handleUnreadNotificationDot();
      }
    },
    unsetUnreadView() {
      if (this.isIFrame) {
        IFrameHelper.sendMessage({ event: 'resetUnreadMode' });
        this.setIframeHeight();
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
      this.isWebWidgetTriggered = true;
      if (
        isWidgetTriggerEvent &&
        (this.showUnreadView || this.showCampaignView)
      ) {
        return;
      }
      this.setUserLastSeen();
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
          this.setPosition(message.position);
          this.fetchOldConversations().then(() => this.setUnreadView());
          this.setPopoutDisplay(message.showPopoutButton);
          this.fetchAvailableAgents(websiteToken);
          this.setHideMessageBubble(message.hideMessageBubble);
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
          this.isMobile = message.showClose;
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
        } else if (message.event === 'set-unread-view') {
          this.showUnreadView = true;
          this.showCampaignView = false;
        } else if (message.event === 'unset-unread-view') {
          // Reset campaign, If widget opened via clciking on bubble button
          if (!this.isCampaignViewClicked) {
            this.resetCampaign();
          }
          this.showUnreadView = false;
          this.showCampaignView = false;
          this.handleUnreadNotificationDot();
        } else if (message.event === 'toggle-open') {
          this.isWidgetOpen = message.isOpen;
          this.toggleOpen();
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
