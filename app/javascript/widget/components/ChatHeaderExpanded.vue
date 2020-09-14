<template>
  <header class="header-expanded">
    <div class="header--row">
      <img v-if="avatarUrl" class="logo" :src="avatarUrl" />
      <header-actions :show-popout-button="showPopoutButton" />
    </div>
    <h2 class="title" v-html="introHeading"></h2>
    <p class="body" v-html="introBody"></p>
  </header>
</template>

<script>
import { mapGetters } from 'vuex';
import HeaderActions from './HeaderActions';
export default {
  name: 'ChatHeaderExpanded',
  components: {
    HeaderActions,
  },
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
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
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

.header--row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
}
</style>
