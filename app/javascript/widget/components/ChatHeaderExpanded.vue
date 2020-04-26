<template>
  <header class="header-expanded">
    <img v-if="avatarUrl" class="logo" :src="avatarUrl" />
    <span class="close close-button" @click="closeWindow"></span>
    <h2 class="title">
      {{ introHeading }}
    </h2>
    <p class="body">
      {{ introBody }}
    </p>
  </header>
</template>

<script>
import { mapGetters } from 'vuex';
import { IFrameHelper } from 'widget/helpers/utils';

export default {
  name: 'ChatHeaderExpanded',
  props: {
    avatarUrl: {
      type: String,
      default: '',
    },
    introHeading: {
      type: String,
      default: '',
    },
    introBody: {
      type: String,
      default: '',
    },
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
  },
  methods: {
    closeWindow() {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({
          event: 'toggleBubble',
        });
      }
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.header-expanded {
  padding: $space-large $space-medium $space-large;
  width: 100%;
  box-sizing: border-box;
  position: relative;

  .logo {
    width: 56px;
    height: 56px;
  }

  .close {
    position: absolute;
    right: $space-medium;
    top: $space-medium;
    display: none;
  }
  .title {
    color: $color-heading;
    font-size: $font-size-mega;
    font-weight: $font-weight-normal;
    margin-bottom: $space-slab;
    margin-top: $space-medium;
  }

  .body {
    color: $color-body;
    font-size: 1.8rem;
    line-height: 1.5;
  }
}
</style>
