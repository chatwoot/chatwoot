<template>
  <div class="widget-wrapper">
    <WidgetHead :config="getWidgetHeadConfig" />
    <WidgetBody />
    <WidgetFooter />
  </div>
</template>

<script>
import WidgetHead from './WidgetHead';
import WidgetBody from './WidgetBody';
import WidgetFooter from './WidgetFooter';

export default {
  name: 'Widget',
  components: {
    WidgetHead,
    WidgetBody,
    WidgetFooter,
  },
  props: {
    welcomeHeading: {
      type: String,
      default: 'Hi There,',
    },
    welcomeTagLine: {
      type: String,
      default: '',
    },
    websiteName: {
      type: String,
      default: '',
      required: true,
    },
    websiteDomain: {
      type: String,
      default: '',
    },
    logo: {
      type: String,
      default: '',
    },
    isExpanded: {
      type: Boolean,
      default: true,
    },
    isOnline: {
      type: Boolean,
      default: true,
    },
    replyTime: {
      type: String,
      default: 'few minutes',
    },
  },
  computed: {
    getWidgetHeadConfig() {
      return {
        welcomeHeading: this.welcomeHeading,
        welcomeTagLine: this.welcomeTagLine,
        websiteName: this.websiteName,
        websiteDomain: this.websiteDomain,
        logo: this.logo,
        isExpanded: this.isExpanded,
        isOnline: this.isOnline,
        replyTime: this.replyTime,
      };
    },
  },
};
</script>

<style lang="scss" scoped>
.text-lg {
  font-size: var(--font-size-default);
}
.widget-wrapper {
  box-shadow: var(--shadow-larger);
  border-radius: var(--border-radius-large);
  background-color: var(--color-background);
  z-index: 99;
}
</style>
