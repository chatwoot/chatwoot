<template>
  <div id="app" class="woot-widget-wrap" :class="{ 'is-mobile': isMobile }">
    <router-view />
  </div>
</template>

<script>
import { mapActions } from 'vuex';
import { setHeader } from 'widget/helpers/axios';
import { IFrameHelper } from 'widget/helpers/utils';

export default {
  name: 'App',
  data() {
    return {
      isMobile: false,
    };
  },
  mounted() {
    const { website_token: websiteToken = '' } = window.chatwootWebChannel;
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
        this.fetchOldConversations();
        this.fetchAvailableAgents(websiteToken);
      } else if (message.event === 'widget-visible') {
        this.scrollConversationToBottom();
      } else if (message.event === 'set-current-url') {
        window.refererURL = message.refererURL;
      } else if (message.event === 'toggle-close-button') {
        this.isMobile = message.showClose;
      }
    });
  },
  methods: {
    ...mapActions('appConfig', ['setWidgetColor']),
    ...mapActions('conversation', ['fetchOldConversations']),
    ...mapActions('agent', ['fetchAvailableAgents']),
    scrollConversationToBottom() {
      const container = this.$el.querySelector('.conversation-wrap');
      container.scrollTop = container.scrollHeight;
    },
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/woot.scss';
</style>
