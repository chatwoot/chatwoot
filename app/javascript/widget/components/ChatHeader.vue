<template>
  <header class="header-collapsed" :style="{ background: widgetColor }">
    <div>
      <h2 class="title">
        {{ title }}
      </h2>
    </div>
  </header>
</template>

<script>
import { mapGetters } from 'vuex';

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
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.header-collapsed {
  background: $color-woot;
  padding: $space-two $space-medium;
  width: 100%;
  box-sizing: border-box;
  color: $color-white;

  .title {
    font-size: $font-size-big;
    font-weight: $font-weight-medium;
  }
}
</style>
