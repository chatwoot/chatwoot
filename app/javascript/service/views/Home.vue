<template>
  <div
    v-if="showHomePage"
    class="flex flex-1 items-center h-full bg-black-25 justify-center"
  >
    <spinner size="" />
  </div>
  <div v-else class="home">
    <div class="flex flex-1 overflow-auto">
      <customer-satisfaction :message-id="messageId" />
    </div>
    <div class="footer-wrap">
      <branding></branding>
    </div>
  </div>
</template>

<script>
import Branding from 'service/components/Branding.vue';
import CustomerSatisfaction from 'shared/components/CustomerSatisfaction';
import configMixin from '../mixins/configMixin';
import Spinner from 'shared/components/Spinner.vue';
export default {
  name: 'Home',
  components: {
    Branding,
    Spinner,
    CustomerSatisfaction,
  },
  mixins: [configMixin],
  props: {
    showHomePage: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      isOnCollapsedView: false,
      isOnNewConversation: false,
      messageId: 1212,
    };
  },
  computed: {
    isHeaderCollapsed() {
      return this.isOnCollapsedView;
    },
    hasIntroText() {
      return (
        this.channelConfig.welcomeTitle || this.channelConfig.welcomeTagline
      );
    },
  },
};
</script>

<style scoped lang="scss">
@import '~service/assets/scss/variables';
@import '~service/assets/scss/mixins';

.home {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  overflow: hidden;
  background: $color-background;

  .header-wrap {
    border-radius: $space-normal $space-normal 0 0;
    flex-shrink: 0;
    transition: max-height 300ms;
    z-index: 99;
    @include shadow-large;

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

  .footer-wrap {
    flex-shrink: 0;
    width: 100%;
    display: flex;
    flex-direction: column;
    position: relative;

    &:before {
      content: '';
      position: absolute;
      top: -$space-normal;
      left: 0;
      width: 100%;
      height: $space-normal;
      opacity: 0.1;
      background: linear-gradient(
        to top,
        $color-background,
        rgba($color-background, 0)
      );
    }
  }

  .input-wrap {
    padding: 0 $space-normal;
  }
}
</style>
