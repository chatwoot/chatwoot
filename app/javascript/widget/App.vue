<template>
  <router
    :show-unread-view="showUnreadView"
    :is-mobile="isMobile"
    :grouped-messages="groupedMessages"
    :unread-messages="unreadMessages"
    :conversation-size="conversationSize"
    :available-agents="availableAgents"
    :has-fetched="hasFetched"
    :conversation-attributes="conversationAttributes"
    :unread-message-count="unreadMessageCount"
    :is-left-aligned="isLeftAligned"
    :hide-message-bubble="hideMessageBubble"
  />
</template>

<script>
/* global bus */

import Vue from 'vue';
import { mapGetters, mapActions } from 'vuex';
import { setHeader } from 'widget/helpers/axios';
import { IFrameHelper } from 'widget/helpers/utils';

import Router from './views/Router';

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
    };
  },
  computed: {
    ...mapGetters({
      groupedMessages: 'conversation/getGroupedConversation',
      unreadMessages: 'conversation/getUnreadTextMessages',
      conversationSize: 'conversation/getConversationSize',
      availableAgents: 'agent/availableAgents',
      hasFetched: 'agent/getHasFetched',
      conversationAttributes: 'conversationAttributes/getConversationParams',
      unreadMessageCount: 'conversation/getUnreadMessageCount',
    }),
    isLeftAligned() {
      const isLeft = this.widgetPosition === 'left';
      return isLeft;
    },
  },
  mounted() {
    const { websiteToken, locale } = window.chatwootWebChannel;
    this.setLocale(locale);

    if (IFrameHelper.isIFrame()) {
      IFrameHelper.sendMessage({
        event: 'loaded',
        config: {
          authToken: window.authToken,
          channelConfig: window.chatwootWebChannel,
        },
      });
      setHeader('X-Auth-Token', window.authToken);
    }
    this.setWidgetColor(window.chatwootWebChannel);

    window.addEventListener('message', e => {
      const wootPrefix = 'chatwoot-widget:';
      const isDataNotString = typeof e.data !== 'string';
      const isNotFromWoot = isDataNotString || e.data.indexOf(wootPrefix) !== 0;

      if (isNotFromWoot) return;

      const message = JSON.parse(e.data.replace(wootPrefix, ''));
      if (message.event === 'config-set') {
        this.setLocale(message.locale);
        this.setBubbleLabel();
        this.setPosition(message.position);
        this.fetchOldConversations().then(() => {
          this.setUnreadView();
        });
        this.fetchAvailableAgents(websiteToken);
        this.setHideMessageBubble(message.hideMessageBubble);
      } else if (message.event === 'widget-visible') {
        this.scrollConversationToBottom();
      } else if (message.event === 'set-current-url') {
        window.refererURL = message.refererURL;
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
      } else if (message.event === 'set-locale') {
        this.setLocale(message.locale);
        this.setBubbleLabel();
      } else if (message.event === 'set-unread-view') {
        this.showUnreadView = true;
      } else if (message.event === 'unset-unread-view') {
        this.showUnreadView = false;
      }
    });

    this.$store.dispatch('conversationAttributes/get');
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
        Vue.config.lang = locale;
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
      bus.$on('on-agent-message-recieved', () => this.setUnreadView());
      bus.$on('on-unread-view-clicked', () => {
        this.unsetUnreadView();
        this.setUserLastSeen();
      });
    },
    setUnreadView() {
      const { unreadMessageCount } = this;
      if (IFrameHelper.isIFrame() && unreadMessageCount > 0) {
        IFrameHelper.sendMessage({
          event: 'setUnreadMode',
          unreadMessageCount,
        });
      }
    },
    unsetUnreadView() {
      if (IFrameHelper.isIFrame()) {
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
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/woot.scss';
</style>
