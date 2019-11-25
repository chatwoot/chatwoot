<template>
  <div id="app" class="woot-widget-wrap">
    <router-view />
  </div>
</template>

<script>
import { mapActions } from 'vuex';
import { setHeader } from './helpers/axios';

export const IFrameHelper = {
  isIFrame: () => window.self !== window.top,
  sendMessage: msg => {
    window.parent.postMessage(
      `chatwoot-widget:${JSON.stringify({ ...msg })}`,
      '*'
    );
  },
};

export default {
  name: 'App',

  methods: {
    ...mapActions('appConfig', ['setWidgetColor']),
    ...mapActions('conversation', ['fetchOldConversations']),
    scrollConversationToBottom() {
      const container = this.$el.querySelector('.conversation-wrap');
      container.scrollTop = container.scrollHeight;
    },
  },

  mounted() {
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
      if (
        typeof e.data !== 'string' ||
        e.data.indexOf('chatwoot-widget:') !== 0
      ) {
        return;
      }
      const message = JSON.parse(e.data.replace('chatwoot-widget:', ''));
      if (message.event === 'config-set') {
        this.fetchOldConversations();
      } else if (message.event === 'widget-visible') {
        this.scrollConversationToBottom();
      }
    });
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/woot.scss';
</style>
