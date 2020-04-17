<template>
  <div class="row settings--form--footer">
    <div v-if="buttonText" class="medium-12 text-right">
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

.settings--form--footer {
  align-items: center;
  display: flex;
  margin-bottom: $space-normal;
  padding: $space-normal 0;

  .button {
    margin-bottom: 0;
  }
}
</style>
