<template>
  <div class="row settings--form--header">
    <div class="medium-8">
      <p class="title">
        {{ title }}
      </p>
      <p class="sub-head">
        {{ subTitle }}
      </p>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    title: {
      type: String,
      required: true,
    },
    subTitle: {
      type: String,
      required: true,
    },
  },
};
</script>

<style lang="scss">
@import '~dashboard/assets/scss/variables';

.settings--form--header {
  align-items: center;
  border-top: 1px solid $color-border;
  display: flex;
  padding: $space-normal 0;

  .title {
    margin-bottom: 0;
    font-size: $font-size-default;
  }
}
</style>
