<template>
  <header class="header-collapsed">
    <h2 class="title">
      {{ title }}
    </h2>
    <span class="close" @click="closeWindow"></span>
  </header>
</template>

<script>
import { mapGetters } from 'vuex';
import { IFrameHelper } from 'widget/helpers/utils';

export default {
  name: 'ChatHeader',
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
  },
  props: {
    title: {
      type: String,
      default: '',
    },
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

.header-collapsed {
  display: flex;
  justify-content: space-between;
  background: $color-white;
  padding: $space-two $space-medium;
  width: 100%;
  box-sizing: border-box;
  color: $color-white;
  border-bottom-left-radius: $space-small;
  border-bottom-right-radius: $space-small;
  @include shadow-large;

  .title {
    font-size: $font-size-large;
    font-weight: $font-weight-medium;
    color: $color-heading;
  }

  .close {
    position: relative;
    margin-right: $space-small;

    &:before,
    &:after {
      position: absolute;
      left: 0;
      top: $space-smaller;
      content: ' ';
      height: $space-normal;
      width: 2px;
      background-color: $color-heading;
    }
    &:before {
      transform: rotate(45deg);
    }
    &:after {
      transform: rotate(-45deg);
    }
  }
}
</style>
