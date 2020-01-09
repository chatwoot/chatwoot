<template>
  <button
    type="submit"
    :disabled="disabled"
    class="send-button"
    @click="onClick"
  >
    <span v-if="!loading" class="icon-holder">
      <i class="ion-android-send" />
    </span>
    <spinner v-else size="small" />
  </button>
</template>

<script>
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    Spinner,
  },
  props: {
    loading: {
      type: Boolean,
      default: false,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    onClick: {
      type: Function,
      default: () => {},
    },
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.send-button {
  background: transparent;
  border: 0;
  cursor: pointer;
  position: relative;

  .icon-holder {
    display: flex;
    align-items: center;
    justify-content: center;
    fill: $color-white;
    font-size: $font-size-big;
    font-weight: $font-weight-medium;
  }
}
</style>
