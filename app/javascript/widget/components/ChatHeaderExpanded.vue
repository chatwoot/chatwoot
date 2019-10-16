<template>
  <header class="header-expanded">
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
export default {
  name: 'ChatHeaderExpanded',
  props: {
    introHeading: {
      type: String,
      default: 'Hi there ! 🙌🏼',
    },
    introBody: {
      type: String,
      default:
        'We make it simple to start a support for your business. Ask us anything, or share your feedback.',
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/woot.scss';

.header-expanded {
  background-image: linear-gradient(to right, #005bea 0%, $color-woot 100%);
  padding: $space-larger $space-large;
  width: 100%;
  box-sizing: border-box;
  height: $header-expanded-height;
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
