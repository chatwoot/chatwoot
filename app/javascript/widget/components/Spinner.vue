<template>
  <span class="spinner" :class="size"></span>
</template>

<script>
const SIZES = ['small', 'medium', 'large'];

export default {
  props: {
    size: {
      validator: value => SIZES.includes(value),
    },
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
@import '~widget/assets/scss/woot.scss';

.spinner {
  @keyframes spinner {
    to {
      transform: rotate(360deg);
    }
  }

  &:before {
    content: '';
    box-sizing: border-box;
    position: absolute;
    top: 50%;
    left: 50%;
    width: $space-medium;
    height: $space-medium;
    margin-top: -$space-slab;
    margin-left: -$space-slab;
    border-radius: 50%;
    border: 2px solid rgba(255, 255, 255, 0.7);
    border-top-color: lighten($color-woot, 10%);
    animation: spinner 0.7s linear infinite;
  }

  &.small:before {
    width: $space-slab;
    height: $space-slab;
    margin-top: -$space-slab/2;
    margin-left: -$space-slab/2;
    border-width: 1px;
  }
}
</style>
