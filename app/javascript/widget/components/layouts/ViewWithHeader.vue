<script>
import Banner from '../Banner.vue';
import Branding from 'shared/components/Branding.vue';
import ChatHeader from '../ChatHeader.vue';
import ChatHeaderExpanded from '../ChatHeaderExpanded.vue';
import TabBar from '../TabBar.vue';
import configMixin from '../../mixins/configMixin';
import { mapGetters } from 'vuex';
import { IFrameHelper } from 'widget/helpers/utils';

export default {
  components: {
    Banner,
    Branding,
    ChatHeader,
    ChatHeaderExpanded,
    TabBar,
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
    backRouteName() {
      const isOnMessages = this.$route.name === 'messages';
      return isOnMessages && this.hasMultipleConversationsEnabled
        ? 'conversations'
        : 'home';
    },
    isOnArticleViewer() {
      return ['article-viewer'].includes(this.$route.name);
    },
    isOnHomeView() {
      return ['home'].includes(this.$route.name);
    },
    isOnTabScreen() {
      return ['home', 'conversations'].includes(this.$route.name);
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
  watch: {
    '$route.name'() {
      this.scrollPosition = 0;
      this.$el.scrollTop = 0;
      this.$refs.content.scrollTop = 0;
    },
  },
  unmounted() {
    cancelAnimationFrame(this.requestID);
  },
  methods: {
    closeWindow() {
      IFrameHelper.sendMessage({ event: 'closeWindow' });
    },
    updateScrollPosition(event) {
      if (!this.isOnHomeView) return;
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
    class="w-full h-full bg-n-surface-1"
    :class="{
      'overflow-auto': isOnHomeView && !hasMultipleConversationsEnabled,
    }"
    @keydown.esc="closeWindow"
    @scroll.capture="updateScrollPosition"
  >
    <div class="relative flex flex-col h-full">
      <div
        ref="content"
        :class="
          hasMultipleConversationsEnabled
            ? [
                'relative flex flex-col flex-1 min-h-0',
                { 'overflow-auto pb-24': isOnHomeView },
              ]
            : 'contents'
        "
      >
        <div
          :class="{
            expanded: !isHeaderCollapsed,
            'collapsed relative z-10': isHeaderCollapsed,
            'shadow-[0_10px_15px_-16px_rgba(50,50,93,0.08),0_4px_6px_-8px_rgba(50,50,93,0.04)]':
              isHeaderCollapsed,
            ...opacityClass,
          }"
        >
          <ChatHeaderExpanded
            v-if="!isHeaderCollapsed"
            :intro-heading="
              appConfig.welcomeTitle || channelConfig.welcomeTitle
            "
            :intro-body="
              appConfig.welcomeDescription || channelConfig.welcomeTagline
            "
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
            :back-route-name="backRouteName"
          />
        </div>
        <Banner />
        <router-view />

        <Branding
          v-if="!isOnArticleViewer"
          :disable-branding="disableBranding"
        />
      </div>
      <TabBar v-if="hasMultipleConversationsEnabled && isOnTabScreen" />
    </div>
  </div>
</template>
