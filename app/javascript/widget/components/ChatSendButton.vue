<template>
  <button
    type="submit"
    :disabled="disabled"
    class="button small send-button"
    @click="onClick"
  >
    <span v-if="!loading" class="icon-holder">send</span>
    <spinner v-else size="small" />
  </button>
</template>

<script>
import Spinner from 'widget/components/Spinner.vue';

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
@import '~widget/assets/scss/woot.scss';

.send-button {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-around;
  min-width: $space-big;
  .icon-holder {
    background: url('~widget/assets/images/message-send.svg') left center
      no-repeat;
    background-size: $space-one;
    padding-left: $space-normal;
    fill: $color-white;
    font-weight: $font-weight-medium;
  }
}
</style>
