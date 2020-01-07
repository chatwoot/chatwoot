<template>
  <header class="header-expanded">
    <div>
      <img
        class="logo"
        src="http://www.hennigcompany.com/wp-content/uploads/2014/06/starbucks-logo.png"
      />
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
  background: $color-white;
  padding: $space-larger $space-medium $space-large;
  width: 100%;
  box-sizing: border-box;
  border-radius: 1.6rem;
  box-shadow: 0 10px 15px -16px rgba(0, 0, 0, 0.1),
    0 4px 6px -8px rgba(0, 0, 0, 0.05) !important;

  .logo {
    width: 64px;
    height: 64px;
  }

  .title {
    color: $color-heading;
    font-size: $font-size-mega;
    font-weight: $font-weight-normal;
    margin-bottom: $space-slab;
    margin-top: $space-large;
  }

  .body {
    color: $color-body;
    font-size: 1.8rem;
    line-height: 1.6;
  }
}
</style>
