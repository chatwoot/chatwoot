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
  @apply bg-n-slate-5;
  --toggle-button-box-shadow: rgb(255, 255, 255) 0px 0px 0px 0px,
    rgba(59, 130, 246, 0.5) 0px 0px 0px 0px, rgba(0, 0, 0, 0.1) 0px 1px 3px 0px,
    rgba(0, 0, 0, 0.06) 0px 1px 2px 0px;
  border-radius: 0.5625rem;
  border: 2px solid transparent;
  cursor: pointer;
  display: flex;
  flex-shrink: 0;
  height: 1.188rem;
  position: relative;
  transition-duration: 200ms;
  transition-property: background-color;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  width: 2.125rem;

  &.active {
    @apply bg-n-brand;
  }

  &.small {
    width: 1.375rem;
    height: 0.875rem;

    span {
      @apply size-2.5;

      &.active {
        @apply ltr:translate-x-[0.5rem] ltr:translate-y-0 rtl:translate-x-[-0.5rem] rtl:translate-y-0;
      }
    }
  }

  span {
    @apply bg-n-background;

    border-radius: 100%;
    box-shadow: var(--toggle-button-box-shadow);
    display: inline-block;
    height: 0.9375rem;
    transform: translate(0, 0);
    transition-duration: 200ms;
    transition-property: transform;
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    width: 0.9375rem;

    &.active {
      @apply ltr:translate-x-[0.9375rem] ltr:translate-y-0 rtl:translate-x-[-0.9375rem] rtl:translate-y-0;
    }
  }
}
</style>
