<template>
  <div
    v-if="showBannerMessage"
    class="banner"
    :class="`banner banner__${bannerType}`"
  >
    <span>
      {{ bannerMessage }}
    </span>
  </div>
</template>

<script>
import { BUS_EVENTS } from 'shared/constants/busEvents';

export default {
  data() {
    return {
      showBannerMessage: false,
      bannerMessage: '',
      bannerType: 'error',
    };
  },
  mounted() {
    bus.$on(BUS_EVENTS.SHOW_ALERT, ({ message, type = 'error' }) => {
      this.bannerMessage = message;
      this.bannerType = type;
      this.showBannerMessage = true;
      setTimeout(() => {
        this.showBannerMessage = false;
      }, 3000);
    });
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
.banner {
  color: $color-white;
  font-size: $font-size-default;
  font-weight: $font-weight-bold;
  padding: $space-slab;
  text-align: center;
  &__success {
    background: $color-success;
  }
  &__error {
    background: $color-error;
  }
}
</style>
