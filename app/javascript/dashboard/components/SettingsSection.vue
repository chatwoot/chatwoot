<template>
  <div class="row settings--section" :class="{ 'border-bottom': showBorder }">
    <div class="medium-4 small-12 title--section">
      <p v-if="title" class="sub-block-title">
        {{ title }}
      </p>
      <p class="sub-head">
        <slot v-if="subTitle" name="subTitle">
          {{ subTitle }}
        </slot>
      </p>
      <p v-if="note">
        <span class="note">{{ $t('INBOX_MGMT.NOTE') }}</span>
        {{ note }}
      </p>
    </div>
    <div class="medium-6 small-12">
      <slot />
    </div>
  </div>
</template>

<script>
export default {
  props: {
    title: {
      type: String,
      default: '',
    },
    subTitle: {
      type: String,
      default: '',
    },
    showBorder: {
      type: Boolean,
      default: true,
    },
    note: {
      type: String,
      default: '',
    },
  },
};
</script>

<style lang="scss">
@import '~dashboard/assets/scss/variables';

.settings--section {
  display: flex;
  padding: 0 $space-normal $space-normal 0;

  &.border-bottom {
    padding-top: $space-normal;
    border-bottom: 1px solid $color-border;
  }

  .sub-block-title {
    color: $color-woot;
    font-weight: $font-weight-medium;
    margin-bottom: 0;
  }

  .title--section {
    padding-right: var(--space-large);
  }

  .note {
    font-weight: var(--font-weight-bold);
  }
}
</style>
