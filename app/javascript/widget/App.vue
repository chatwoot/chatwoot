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
    ...mapActions('conversation', ['fetchOldConversations']),
  },

  mounted() {
    if (IFrameHelper.isIFrame()) {
      IFrameHelper.sendMessage({
        event: 'loaded',
        config: {
          authToken: window.authToken,
        },
      });
      setHeader('X-Auth-Token', window.authToken);
    }

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
      }
    });
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/woot.scss';
</style>
