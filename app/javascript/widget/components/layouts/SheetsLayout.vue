<template>
  <div
    class="w-full h-full flex flex-col brand-bg relative"
    @keydown.esc="closeWindow"
  >
    <top-bar
      v-if="isRNWebView"
      @back="onBackButtonClick"
      @close="closeWindow"
    />
    <banner />
    <transition
      enter-class="translate-y-8 opacity-0 group is-animating"
      enter-active-class="transition-all duration-300 ease-in"
      enter-to-class="opacity-100 translate-y-0"
      leave-class="opacity-100 translate-y-0"
      leave-active-class="transition-all duration-400 ease-out"
      leave-to-class="translate-y-8 opacity-0"
      mode="out-in"
    >
      <router-view />
    </transition>
    <div class="w-full sticky bottom-0 -z-0">
      <branding :disable-branding="disableBranding" />
    </div>
  </div>
</template>
<script>
import Banner from '../Banner.vue';
import TopBar from '../TopBar.vue';
import Branding from 'shared/components/Branding.vue';
import configMixin from '../../mixins/configMixin';
import darkModeMixin from 'widget/mixins/darkModeMixin';
import { mapGetters } from 'vuex';

import { IFrameHelper, RNHelper } from 'widget/helpers/utils';

export default {
  components: {
    Banner,
    Branding,
    TopBar,
  },
  mixins: [configMixin, darkModeMixin],
  data() {
    return {
      showPopoutButton: false,
      disableBranding: window.chatwootWebChannel.disableBranding || false,
    };
  },
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      appConfig: 'appConfig/getAppConfig',
    }),
    isHeaderVisible() {
      return this.$route.name !== 'home';
    },
    hasIntroText() {
      return (
        this.channelConfig.welcomeTitle || this.channelConfig.welcomeTagline
      );
    },
    isRNWebView() {
      return RNHelper.isRNWebView();
    },
  },
  methods: {
    onBackButtonClick() {
      this.replaceRoute('home');
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
.brand-bg {
  background: var(--brand-primary);
}
</style>
