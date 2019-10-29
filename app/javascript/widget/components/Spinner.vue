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
@import '~widget/assets/scss/variables.scss';

.spinner {
  @keyframes spinner {
    to {
      transform: rotate(360deg);
    }
  }

  &:before {
    animation: spinner 0.7s linear infinite;
    border-radius: 50%;
    border-top-color: lighten($color-woot, 10%);
    border: 2px solid rgba(255, 255, 255, 0.7);
    box-sizing: border-box;
    content: '';
    height: $space-medium;
    left: 50%;
    margin-left: -$space-slab;
    margin-top: -$space-slab;
    position: absolute;
    top: 50%;
    width: $space-medium;
  }

  &.small:before {
    border-width: 1px;
    height: $space-slab;
    margin-left: -$space-slab/2;
    margin-top: -$space-slab/2;
    width: $space-slab;
  }
}
</style>
