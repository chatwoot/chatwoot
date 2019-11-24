<template>
  <header class="header-expanded" :style="{ background: widgetColor }">
    <div>
      <h2 class="title">
        {{ introHeading }}
      </h2>
      <p class="body">
        {{ introBody }}
      </p>
    </div>
  </header>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  name: 'ChatHeaderExpanded',
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
  },
  props: {
    introHeading: {
      type: String,
      default: 'Hi there ! 🙌🏼',
    },
    introBody: {
      type: String,
      default:
        'We make it simple to connect with us. Ask us anything, or share your feedback.',
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.header-expanded {
  background: $color-woot;
  padding: $space-large;
  width: 100%;
  box-sizing: border-box;
  color: $color-white;

  .title {
    font-size: $font-size-mega;
    margin-bottom: $space-two;
  }

  .body {
    font-size: $font-size-medium;
    line-height: 1.5;
  }
}
</style>
