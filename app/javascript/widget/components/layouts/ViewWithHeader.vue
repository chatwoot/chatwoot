<script>
import Banner from '../Banner.vue';
import Branding from 'shared/components/Branding.vue';
import ChatHeader from '../ChatHeader.vue';
import ChatHeaderExpanded from '../ChatHeaderExpanded.vue';
import configMixin from '../../mixins/configMixin';
import { mapGetters } from 'vuex';
import { IFrameHelper } from 'widget/helpers/utils';

export default {
  components: {
    Banner,
    Branding,
    ChatHeader,
    ChatHeaderExpanded,
  },
  mixins: [configMixin],
  data() {
    return {
      showPopoutButton: false,
      scrollPosition: 0,
      ticking: true,
      disableBranding: window.chatwootWebChannel.disableBranding || false,
      requestID: null,
    };
  },
  computed: {
    ...mapGetters({
      appConfig: 'appConfig/getAppConfig',
      availableAgents: 'agent/availableAgents',
    }),
    portal() {
      return window.chatwootWebChannel.portal;
    },
    isHeaderCollapsed() {
      if (!this.hasIntroText) {
        return true;
      }
      return !this.isOnHomeView;
    },
    hasIntroText() {
      return (
        this.channelConfig.welcomeTitle || this.channelConfig.welcomeTagline
      );
    },
    showBackButton() {
      return ['article-viewer', 'messages', 'prechat-form'].includes(
        this.$route.name
      );
    },
    isOnArticleViewer() {
      return ['article-viewer'].includes(this.$route.name);
    },
    isOnHomeView() {
      return ['home'].includes(this.$route.name);
    },
    opacityClass() {
      if (this.isHeaderCollapsed) {
        return {};
      }
      if (this.scrollPosition > 30) {
        return { 'opacity-30': true };
      }
      if (this.scrollPosition > 25) {
        return { 'opacity-40': true };
      }
      if (this.scrollPosition > 20) {
        return { 'opacity-60': true };
      }
      if (this.scrollPosition > 15) {
        return { 'opacity-80': true };
      }
      if (this.scrollPosition > 10) {
        return { 'opacity-90': true };
      }
      return {};
    },
  },
  mounted() {
    this.$el.addEventListener('scroll', this.updateScrollPosition);
  },
  unmounted() {
    this.$el.removeEventListener('scroll', this.updateScrollPosition);
    cancelAnimationFrame(this.requestID);
  },
  methods: {
    closeWindow() {
      IFrameHelper.sendMessage({ event: 'closeWindow' });
    },
    updateScrollPosition(event) {
      this.scrollPosition = event.target.scrollTop;
      if (!this.ticking) {
        this.requestID = window.requestAnimationFrame(() => {
          this.ticking = false;
        });

        this.ticking = true;
      }
    },
  },
};
</script>

<template>
  <div
    class="w-full h-full bg-slate-25 dark:bg-slate-800"
    :class="{ 'overflow-auto': isOnHomeView }"
    @keydown.esc="closeWindow"
  >
    <div class="relative flex flex-col h-full">
      <div
        class="sticky top-0 z-40 transition-all header-wrap"
        :class="{
          expanded: !isHeaderCollapsed,
          collapsed: isHeaderCollapsed,
          'custom-header-shadow': isHeaderCollapsed,
          ...opacityClass,
        }"
      >
        <ChatHeaderExpanded
          v-if="!isHeaderCollapsed"
          :intro-heading="channelConfig.welcomeTitle"
          :intro-body="channelConfig.welcomeTagline"
          :avatar-url="channelConfig.avatarUrl"
          :show-popout-button="appConfig.showPopoutButton"
        />
        <ChatHeader
          v-if="isHeaderCollapsed"
          :title="channelConfig.websiteName"
          :avatar-url="channelConfig.avatarUrl"
          :show-popout-button="appConfig.showPopoutButton"
          :available-agents="availableAgents"
          :show-back-button="showBackButton"
        />
      </div>
      <Banner />
      <router-view />

      <Branding v-if="!isOnArticleViewer" :disable-branding="disableBranding" />
    </div>
  </div>
</template>

<style scoped lang="scss">
@import 'widget/assets/scss/variables';
@import 'widget/assets/scss/mixins';

.custom-header-shadow {
  @include shadow-large;
}

.header-wrap {
  flex-shrink: 0;
  transition: max-height 100ms;

  &.expanded {
    max-height: 16rem;
  }

  &.collapsed {
    max-height: 4.5rem;
  }

  @media only screen and (min-device-width: 320px) and (max-device-width: 667px) {
    border-radius: 0;
  }
}
</style>
