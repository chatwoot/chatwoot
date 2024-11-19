<script>
export default {
  props: {
    modelValue: { type: Boolean, default: false },
    size: { type: String, default: '' },
  },
  emits: ['update:modelValue', 'input'],
  methods: {
    onClick() {
      this.$emit('update:modelValue', !this.modelValue);
      this.$emit('input', !this.modelValue);
    },
  },
};
</script>

<template>
  <button
    type="button"
    class="toggle-button p-0"
    :class="{ active: modelValue, small: size === 'small' }"
    role="switch"
    :aria-checked="modelValue.toString()"
    @click="onClick"
  >
    <span aria-hidden="true" :class="{ active: modelValue }" />
  </button>
</template>

<style lang="scss" scoped>
.toggle-button {
  @apply bg-slate-200 dark:bg-slate-600;
  --toggle-button-box-shadow: rgb(255, 255, 255) 0px 0px 0px 0px,
    rgba(59, 130, 246, 0.5) 0px 0px 0px 0px, rgba(0, 0, 0, 0.1) 0px 1px 3px 0px,
    rgba(0, 0, 0, 0.06) 0px 1px 2px 0px;
  border-radius: var(--border-radius-large);
  border: 2px solid transparent;
  cursor: pointer;
  display: flex;
  flex-shrink: 0;
  height: 19px;
  position: relative;
  transition-duration: 200ms;
  transition-property: background-color;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  width: 34px;

  &.active {
    background-color: var(--w-500);
  }

  &.small {
    width: 22px;
    height: 14px;

    span {
      height: var(--space-one);
      width: var(--space-one);

      &.active {
        transform: translate(var(--space-small), var(--space-zero));
      }
    }
  }

  span {
    @apply bg-white dark:bg-slate-900;
    --space-one-point-five: 0.9375rem;
    border-radius: 100%;
    box-shadow: var(--toggle-button-box-shadow);
    display: inline-block;
    height: var(--space-one-point-five);
    transform: translate(0, 0);
    transition-duration: 200ms;
    transition-property: transform;
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    width: var(--space-one-point-five);

    &.active {
      transform: translate(var(--space-one-point-five), var(--space-zero));
    }
  }
}
</style>
