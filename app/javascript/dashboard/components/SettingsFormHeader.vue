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
    <div v-if="buttonText" class="medium-4 text-right">
      <woot-submit-button
        class="default"
        :button-text="buttonText"
        :loading="isUpdating"
        @click="onClick()"
      />
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
    buttonText: {
      type: String,
      default: '',
    },
    isUpdating: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    onClick() {
      this.$emit('update');
    },
  },
};
</script>

<style lang="scss">
@import '~dashboard/assets/scss/variables';

.settings--form--header {
  align-items: center;
  border-bottom: 1px solid $color-border;
  display: flex;
  margin-bottom: $space-normal;
  padding: $space-normal 0;

  .button {
    margin-bottom: 0;
  }

  .title {
    margin-bottom: 0;
    font-size: $font-size-default;
  }
}
</style>
