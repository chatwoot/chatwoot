<template>
  <div class="row settings--section">
    <div class="medium-4 small-12 title--section">
      <p class="sub-block-title">
        {{ title }}
      </p>
      <p class="sub-head">
        {{ subTitle }}
      </p>
      <p v-if="note">
        <span class="note">{{ $t('INBOX_MGMT.NOTE') }}</span>
        {{ note }}
      </p>
    </div>
    <div class="medium-6 small-12">
      <slot></slot>
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
  border-bottom: 1px solid $color-border;
  display: flex;
  padding: $space-normal $space-normal $space-normal 0;

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
