<template>
  <button
    type="submit"
    :disabled="disabled"
    class="send-button"
    @click="onClick"
  >
    <span
      v-if="!loading"
      :style="`background-color: ${color}`"
      class="icon-holder"
    ></span>
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
    fill: $color-white;
    font-weight: $font-weight-medium;
    width: $space-two;
    height: $space-two;
    -webkit-mask-image: url("data:image/svg+xml;charset=utf8,%3Csvg width='20' height='20' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M18.34 7.32l-14-7a3 3 0 00-4.08 3.9l2.4 5.37c.11.262.11.558 0 .82l-2.4 5.37A3 3 0 003 20a3.14 3.14 0 001.35-.32l14-7a3 3 0 000-5.36h-.01zm-.89 3.57l-14 7a1 1 0 01-1.35-1.3l2.39-5.37a2 2 0 00.08-.22h6.89a1 1 0 000-2H4.57a2 2 0 00-.08-.22L2.1 3.41a1 1 0 011.35-1.3l14 7a1 1 0 010 1.78z' fill='%23999A9B' fill-rule='nonzero'/%3E%3C/svg%3E");
    mask-image: url("data:image/svg+xml;charset=utf8,%3Csvg width='20' height='20' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M18.34 7.32l-14-7a3 3 0 00-4.08 3.9l2.4 5.37c.11.262.11.558 0 .82l-2.4 5.37A3 3 0 003 20a3.14 3.14 0 001.35-.32l14-7a3 3 0 000-5.36h-.01zm-.89 3.57l-14 7a1 1 0 01-1.35-1.3l2.39-5.37a2 2 0 00.08-.22h6.89a1 1 0 000-2H4.57a2 2 0 00-.08-.22L2.1 3.41a1 1 0 011.35-1.3l14 7a1 1 0 010 1.78z' fill='%23999A9B' fill-rule='nonzero'/%3E%3C/svg%3E");
  }
}
</style>
