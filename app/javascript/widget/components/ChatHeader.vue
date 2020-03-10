<template>
  <header class="header-collapsed">
    <h2 class="title">
      {{ title }}
    </h2>
    <span class="close-button" @click="closeWindow"></span>
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
  padding: $space-two $space-medium;
  width: 100%;
  box-sizing: border-box;
  color: $color-white;

  .title {
    font-size: $font-size-large;
    font-weight: $font-weight-medium;
    color: $color-heading;
  }

  .close-button {
    display: none;
  }
}
</style>
