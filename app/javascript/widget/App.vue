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
      'is-widget-right': !isLeftAligned,
      'is-bubble-hidden': hideMessageBubble,
    }"
  >
    <router-view></router-view>
  </div>
</template>

<script>
import { mapGetters, mapActions, mapMutations } from 'vuex';
import { setHeader } from 'widget/helpers/axios';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';
import configMixin from './mixins/configMixin';
import availabilityMixin from 'widget/mixins/availability';
import { getLocale } from './helpers/urlParamsHelper';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { isEmptyObject } from 'widget/helpers/utils';
import Spinner from 'shared/components/Spinner.vue';

export default {
  name: 'App',
  components: {
    Spinner,
  },
  mixins: [availabilityMixin, configMixin],
  data() {
    return {
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
      conversationSize: 'conversation/getConversationSize',
      isFetchingList: 'conversation/getIsFetchingList',
      hasFetched: 'agent/getHasFetched',
      messageCount: 'conversation/getMessageCount',
      unreadMessageCount: 'conversation/getUnreadMessageCount',
      campaigns: 'campaign/getCampaigns',
      activeCampaign: 'campaign/getActiveCampaign',
      currentUser: 'contacts/getCurrentUser',
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
    '$router.name'() {
      console.log(this.$router);
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
    ...mapActions('appConfig', ['setWidgetColor']),
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
    },
    setHideMessageBubble(hideBubble) {
      this.hideMessageBubble = !!hideBubble;
    },
    registerUnreadEvents() {
      bus.$on('on-agent-message-received', () => {
        if (!this.isIFrame || this.isWidgetOpen) {
          // this.setUserLastSeen();
        }
        this.setUnreadView();
      });
      bus.$on('on-unread-view-clicked', () => {
        this.unsetUnreadView();
        // this.setUserLastSeen();
      });
    },
    registerCampaignEvents() {
      bus.$on('on-campaign-view-clicked', () => {
        this.isCampaignViewClicked = true;
        this.unsetUnreadView();
        // this.setUserLastSeen();
        const showPreChatForm =
          this.preChatFormEnabled && this.preChatFormOptions.requireEmail;
        const isUserEmailAvailable = !!this.currentUser.email;
        if (showPreChatForm && !isUserEmailAvailable) {
          this.$router.replace({ name: 'prechat-form' });
        } else {
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
        IFrameHelper.sendMessage({ event: 'setCampaignMode' });
        this.$router.replace({ name: 'campaigns' });
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
        ['unread-messages', 'campaigns'].includes(this.$route.name)
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
          this.$store.dispatch(
            'contacts/deleteCustomAttribute',
            message.customAttribute
          );
        } else if (message.event === 'set-locale') {
          this.setLocale(message.locale);
          this.setBubbleLabel();
        } else if (message.event === 'set-unread-view') {
          this.$router.replace({ name: 'unread-messages' });
        } else if (message.event === 'unset-unread-view') {
          // Reset campaign, If widget opened via clciking on bubble button
          if (!this.isCampaignViewClicked) {
            this.resetCampaign();
            this.$router.replace({ name: 'messages' });
          }
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
        },
      });
    },
    sendRNWebViewLoadedEvent() {
      RNHelper.sendMessage({
        event: 'loaded',
        config: {
          authToken: window.authToken,
          channelConfig: window.chatwootWebChannel,
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
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/woot.scss';
</style>
