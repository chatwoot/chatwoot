<template>
  <span class="spinner" :class="`${size} ${colorSchemeClasses}`" />
</template>
<script>
export default {
  props: {
    size: {
      type: String,
      default: 'small',
    },
    colorScheme: {
      type: String,
      default: '',
    },
  },
  computed: {
    colorSchemeClasses() {
      if (this.colorScheme === 'primary') {
        return 'before:!border-t-woot-500';
      }

      if (this.colorScheme === 'warning') {
        return 'before:!border-t-yellow-500';
      }

      if (this.colorScheme === 'success') {
        return 'before:!border-t-success-500';
      }

      return this.colorScheme;
    },
  },
};
</script>
<style scoped lang="scss">
@import '~widget/assets/scss/variables';

@mixin color-spinner() {
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
    margin-top: -$space-one;
    margin-left: -$space-one;
    border-radius: 50%;
    border: 2px solid rgba(255, 255, 255, 0.8);
    border-top-color: rgba(255, 255, 255, 0.3);
    animation: spinner 0.9s linear infinite;
  }
}

.spinner {
  @include color-spinner();
  position: relative;
  display: inline-block;
  width: $space-medium;
  height: $space-medium;
  padding: $zero $space-medium;
  vertical-align: middle;

  &.message {
    padding: $space-one;
    top: 0;
    left: 0;
    margin: 0 auto;
    margin-top: $space-slab;
    background: $color-white;
    border-radius: $space-large;

    &:before {
      margin-top: -$space-slab;
      margin-left: -$space-slab;
    }
  }

  &.small {
    width: $space-normal;
    height: $space-normal;

    &:before {
      width: $space-normal;
      height: $space-normal;
      margin-top: -$space-small;
    }
  }

  &.tiny {
    width: $space-one;
    height: $space-one;
    padding: 0 $space-smaller;

    &:before {
      width: $space-one;
      height: $space-one;
      margin-top: -$space-small + $space-micro;
    }
  }

  &.dark::before {
    border-color: rgba(0, 0, 0, 0.7);
    border-top-color: rgba(0, 0, 0, 0.2);
  }
}
</style>
