<template>
  <div
    class="w-full h-full flex flex-col relative bg-slate-50 dark:bg-slate-800"
    :class="{ 'overflow-auto': isOnHomeView }"
    :style="portal ? { backgroundColor: backgroundColor } : {}"
    @keydown.esc="closeWindow"
  >
    <div
      class="header-wrap sticky top-0 z-40"
      :class="{
        expanded: !isHeaderCollapsed,
        collapsed: isHeaderCollapsed,
        'custom-header-shadow': (isOnHomeView && !portal) || !isOnArticleViewer,
      }"
    >
      <transition
        enter-active-class="transition-all delay-200 duration-300 ease-in"
        leave-active-class="transition-all duration-200 ease-out"
        enter-class="opacity-0"
        enter-to-class="opacity-100"
        leave-class="opacity-100"
        leave-to-class="opacity-0"
      >
        <chat-header-expanded
          v-if="!isHeaderCollapsed"
          :intro-heading="channelConfig.welcomeTitle"
          :intro-body="channelConfig.welcomeTagline"
          :avatar-url="channelConfig.avatarUrl"
          :show-popout-button="appConfig.showPopoutButton"
          :show-bg="!!portal"
        />
        <chat-header
          v-if="isHeaderCollapsed"
          :title="channelConfig.websiteName"
          :avatar-url="channelConfig.avatarUrl"
          :show-popout-button="appConfig.showPopoutButton"
          :available-agents="availableAgents"
          :show-back-button="showBackButton"
        />
      </transition>
    </div>
    <banner />
    <transition
      enter-active-class="transition-all delay-300 duration-300 ease-in"
      leave-active-class="transition-all duration-200 ease-out"
      enter-class="opacity-0"
      enter-to-class="opacity-100"
      leave-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <router-view />
    </transition>
    <branding v-if="!isOnArticleViewer" :disable-branding="disableBranding" />
  </div>
</template>
<script>
import Banner from '../Banner.vue';
import Branding from 'shared/components/Branding.vue';
import ChatHeader from '../ChatHeader.vue';
import ChatHeaderExpanded from '../ChatHeaderExpanded.vue';
import configMixin from '../../mixins/configMixin';
import darkModeMixin from 'widget/mixins/darkModeMixin';
import { mapGetters } from 'vuex';
import { IFrameHelper } from 'widget/helpers/utils';

export default {
  components: {
    Banner,
    Branding,
    ChatHeader,
    ChatHeaderExpanded,
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
      appConfig: 'appConfig/getAppConfig',
      availableAgents: 'agent/availableAgents',
      widgetColor: 'appConfig/getWidgetColor',
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
    backgroundColor() {
      const color = this.widgetColor.replace('#', '');
      const r = parseInt(color.slice(0, 2), 16);
      const g = parseInt(color.slice(2, 4), 16);
      const b = parseInt(color.slice(4, 6), 16);
      return `rgba(${r},${g},${b}, 0.02)`;
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
  },
  methods: {
    closeWindow() {
      IFrameHelper.sendMessage({ event: 'closeWindow' });
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables';
@import '~widget/assets/scss/mixins';

.custom-header-shadow {
  @include shadow-large;
}

.header-wrap {
  flex-shrink: 0;
  transition: max-height 300ms;

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
