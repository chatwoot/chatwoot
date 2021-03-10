<template>
  <router
    :show-unread-view="showUnreadView"
    :is-mobile="isMobile"
    :has-fetched="hasFetched"
    :unread-message-count="unreadMessageCount"
    :is-left-aligned="isLeftAligned"
    :hide-message-bubble="hideMessageBubble"
    :show-popout-button="showPopoutButton"
  />
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import { setHeader } from 'widget/helpers/axios';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';

import Router from './views/Router';
import { getLocale } from './helpers/urlParamsHelper';
import { BUS_EVENTS } from 'shared/constants/busEvents';

export default {
  name: 'App',
  components: {
    Router,
  },
  data() {
    return {
      showUnreadView: false,
      isMobile: false,
      hideMessageBubble: false,
      widgetPosition: 'right',
      showPopoutButton: false,
    };
  },
  computed: {
    ...mapGetters({
      hasFetched: 'agent/getHasFetched',
      unreadMessageCount: 'conversation/getUnreadMessageCount',
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
    this.$store.dispatch('conversationAttributes/get');
    this.setWidgetColor(window.chatwootWebChannel);
    this.registerUnreadEvents();
  },
  methods: {
    ...mapActions('appConfig', ['setWidgetColor']),
    ...mapActions('conversation', ['fetchOldConversations', 'setUserLastSeen']),
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
      bus.$on('on-agent-message-recieved', () => {
        if (!this.isIFrame) {
          this.setUserLastSeen();
        }
        this.setUnreadView();
      });
      bus.$on('on-unread-view-clicked', () => {
        this.unsetUnreadView();
        this.setUserLastSeen();
      });
    },
    setPopoutDisplay(showPopoutButton) {
      this.showPopoutButton = showPopoutButton;
    },
    setUnreadView() {
      const { unreadMessageCount } = this;
      if (this.isIFrame && unreadMessageCount > 0) {
        IFrameHelper.sendMessage({
          event: 'setUnreadMode',
          unreadMessageCount,
        });
      }
    },
    unsetUnreadView() {
      if (this.isIFrame) {
        IFrameHelper.sendMessage({ event: 'resetUnreadMode' });
      }
    },
    createWidgetEvents(message) {
      const { eventName } = message;
      const isWidgetTriggerEvent = eventName === 'webwidget.triggered';
      if (isWidgetTriggerEvent && this.showUnreadView) {
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
        } else if (message.event === 'widget-visible') {
          this.scrollConversationToBottom();
        } else if (message.event === 'set-current-url') {
          window.referrerURL = message.referrerURL;
          bus.$emit(BUS_EVENTS.SET_REFERRER_HOST, message.referrerHost);
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
          this.showUnreadView = true;
        } else if (message.event === 'unset-unread-view') {
          this.showUnreadView = false;
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
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/woot.scss';
</style>
