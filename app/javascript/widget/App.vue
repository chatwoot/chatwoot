<template>
  <div
    id="app"
    class="woot-widget-wrap"
    :class="{
      'is-mobile': isMobile,
      'is-widget-right': !isLeftAligned,
      'is-bubble-hidden': isChatTriggerHidden,
    }"
  >
    <transition name="fade" mode="out-in">
      <router-view></router-view>
    </transition>
  </div>
</template>

<script>
import { mapGetters, mapActions, mapMutations } from 'vuex';
import { setHeader } from 'widget/helpers/axios';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';

import { getLocale } from './helpers/urlParamsHelper';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { isEmptyObject } from 'widget/helpers/utils';
import availabilityMixin from 'widget/mixins/availability';

export default {
  name: 'App',
  mixins: [availabilityMixin],
  data() {
    return {
      widgetPosition: 'right',
      showCampaignView: false,
      isMobile: false,
      isChatTriggerHidden: false,
      showPopoutButton: false,
      isWebWidgetTriggered: false,
      isWidgetOpen: false,
    };
  },
  computed: {
    ...mapGetters({
      widgetSettings: 'appConfig/getWidgetSettings',
      messageCount: 'conversation/getMessageCount',
      unreadMessagesIn: 'conversationV2/unreadTextMessagesCountIn',
      campaigns: 'campaign/getCampaigns',
      activeCampaign: 'campaign/getActiveCampaign',
      lastActiveConversationId: 'conversationV2/lastActiveConversationId',
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
    unreadMessageCount() {
      return this.unreadMessagesIn(this.lastActiveConversationId);
    },
  },
  watch: {
    activeCampaign() {
      this.setCampaignView();
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

      this.fetchAvailableAgents(websiteToken);
      this.setLocale(getLocale(window.location.search));
    }
    if (this.isRNWebView) {
      this.registerListeners();
      this.sendRNWebViewLoadedEvent();
    }
    this.fetchContact();
    this.fetchAllConversations();
    this.$store.dispatch('conversationAttributes/getAttributes');
    this.setWidgetColor(window.chatwootWebChannel);
    this.registerUnreadEvents();
    this.registerCampaignEvents();
  },
  methods: {
    ...mapActions('appConfig', ['setWidgetColor']),
    ...mapActions('campaign', ['initCampaigns', 'executeCampaign']),
    ...mapActions('agent', ['fetchAvailableAgents']),
    ...mapActions('conversationV2', [
      'fetchOldMessagesIn',
      'setUserLastSeenIn',
    ]),
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
        const extraHeight = this.getExtraSpaceToscroll();
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
      this.$store.dispatch('appConfig/setWidgetSettings', { widgetPosition });
    },
    setIsChatTriggerHidden(hideBubble) {
      this.$store.dispatch('appConfig/setWidgetSettings', {
        isChatTriggerHidden: !!hideBubble,
      });
    },
    registerUnreadEvents() {
      bus.$on('on-agent-message-received', () => {
        this.setUnreadView();
      });
      bus.$on('on-unread-view-clicked', conversationId => {
        this.$router.replace({
          name: 'home',
        });
        this.$router.push({
          name: 'chat',
          params: {
            conversationId,
          },
        });
        this.unsetUnreadView();
        this.setUserLastSeen();
      });
    },
    registerCampaignEvents() {
      bus.$on('on-campaign-view-clicked', campaignId => {
        const { websiteToken } = window.chatwootWebChannel;
        this.showCampaignView = false;
        this.showUnreadView = false;
        this.$router.replace({ name: 'chat', conversationId: campaignId });
        this.unsetUnreadView();
        debugger;
        this.executeCampaign({ campaignId, websiteToken });
      });
    },
    setPopoutDisplay(showPopoutButton) {
      this.showPopoutButton = showPopoutButton;
    },
    setCampaignView() {
      const { unreadMessageCount, activeCampaign } = this;
      const isCampaignReadyToExecute =
        !isEmptyObject(activeCampaign) &&
        !unreadMessageCount &&
        !this.isWebWidgetTriggered;
      if (this.isIFrame && isCampaignReadyToExecute) {
        const currentRouteName = this.$route.name;
        if (currentRouteName !== 'campaign') {
          this.$router.replace({ name: 'campaign' });
          this.setIframeHeight(this.isMobile);
        }
        IFrameHelper.sendMessage({
          event: 'setCampaignMode',
        });
        this.setIframeHeight(this.isMobile);
      }
    },
    setUnreadView() {
      const { unreadMessageCount } = this;
      if (this.isIFrame && unreadMessageCount > 0) {
        const currentRouteName = this.$route.name;
        if (currentRouteName !== 'unread') {
          this.$router.replace({ name: 'unread' });
          this.setIframeHeight(this.isMobile);
        }
        IFrameHelper.sendMessage({
          event: 'setUnreadMode',
          unreadMessageCount,
        });
      }
    },
    unsetUnreadView() {
      if (this.isIFrame) {
        IFrameHelper.sendMessage({ event: 'resetUnreadMode' });
        this.setIframeHeight();
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
      // this.setUserLastSeen();
      // TODO - what is this for
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
          this.setPopoutDisplay(message.showPopoutButton);
          this.fetchAvailableAgents(websiteToken);
          this.setIsChatTriggerHidden(message.hideMessageBubble);
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
          bus.$emit(BUS_EVENTS.SET_REFERRER_HOST, referrerHost);
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
          this.$store.dispatch('contacts/setCustomAttributes', {
            [message.customAttribute]: null,
          });
        } else if (message.event === 'set-locale') {
          this.setLocale(message.locale);
          this.setBubbleLabel();
        } else if (message.event === 'set-unread-view') {
          this.setUnreadView();
          this.showCampaignView = false;
        } else if (message.event === 'unset-unread-view') {
          this.showCampaignView = false;
        } else if (message.event === 'toggle-open') {
          this.isWidgetOpen = message.isOpen;
          this.toggleOpen();
        }
      });
    },
    sendLoadedEvent() {
      IFrameHelper.sendMessage({
        event: 'loaded',
        config: {
          authToken: window.authToken,
          channelConfig: window.chatwootWebChannel,
          contactIdentifier: window.contactIdentifier,
        },
      });
    },
    sendRNWebViewLoadedEvent() {
      RNHelper.sendMessage({
        event: 'loaded',
        config: {
          authToken: window.authToken,
          channelConfig: window.chatwootWebChannel,
          contactIdentifier: window.contactIdentifier,
        },
      });
    },
    getExtraSpaceToscroll: () => {
      // This function calculates the extra space needed for the view to
      // accomodate the height of close button + height of
      // read messages button. So that scrollbar won't appear
      const unreadMessageWrap = document.querySelector('.unread-messages');
      const unreadCloseWrap = document.querySelector('.close-unread-wrap');
      const readViewWrap = document.querySelector('.open-read-view-wrap');

      if (!unreadMessageWrap) return 0;

      // 24px to compensate the paddings
      let extraHeight = 24 + unreadMessageWrap.scrollHeight;
      if (unreadCloseWrap) extraHeight += unreadCloseWrap.scrollHeight;
      if (readViewWrap) extraHeight += readViewWrap.scrollHeight;

      return extraHeight;
    },
    fetchContact() {
      this.$store.dispatch('contactV2/get').then(() => {
        this.sendLoadedEvent();
      });
    },
    async fetchAllConversations() {
      const conversationId = this.lastActiveConversationId;
      await this.$store.dispatch('conversationV2/fetchAllConversations');

      if (conversationId) {
        await this.fetchOldMessagesIn(this.lastActiveConversationId);
        this.setUnreadView();
      }
    },
    setUserLastSeen() {
      const conversationId = this.lastActiveConversationId;
      if (conversationId) {
        this.setUserLastSeenIn({ conversationId });
      }
    },
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/woot.scss';
</style>
