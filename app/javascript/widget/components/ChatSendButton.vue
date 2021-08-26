<template>
  <button
    type="submit"
    :disabled="disabled"
    class="send-button ml-1"
    @click="onClick"
  >
    <i
      v-if="!loading"
      class="ion-android-send icon-holder"
      :style="`color: ${color}`"
    />
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
    color: {
      type: String,
      default: '#6e6f73',
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
  padding-right: $space-smaller;

  .icon-holder {
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: $font-size-big;
    font-weight: $font-weight-medium;
  }
}
</style>
