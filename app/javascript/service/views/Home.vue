<template>
  <div class="home">
    <div class="flex flex-1 overflow-auto">
      <div class="container">
        <img src="/brand-assets/logo.svg" alt="Chatwoot logo" class="logo" />
        <h2 class="rating--intro">
          Dear customer 👋, please give us some feeback on our chatbot.
        </h2>
        <h2 class="rating--header">Share your feedback</h2>
        <rating />
        <input class="form-input" :placeholder="$t('CSAT.PLACEHOLDER')" />
        <custom-button class="button font-medium" block> Submit </custom-button>
      </div>
    </div>
    <div class="footer-wrap">
      <branding></branding>
    </div>
  </div>
</template>

<script>
import Branding from 'service/components/Branding.vue';
import Rating from 'service/components/Rating.vue';
import CustomButton from 'shared/components/Button';
import configMixin from '../mixins/configMixin';
export default {
  name: 'Home',
  components: {
    Branding,
    Rating,
    CustomButton,
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
  background: $color-white;
  .container {
    min-width: 476px;
    max-width: 476px;
    margin: 0 auto;
    padding: 1rem;
  }
  .logo {
    width: 500px;
  }
  .rating--intro {
    font-size: $font-size-default;
    padding-top: 1rem;
  }
  .rating--header {
    font-size: $font-size-small;
    font-weight: $font-weight-medium;
    padding-top: 1rem;
  }
  .button {
    margin-top: 1rem;
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
