<template>
  <button
    type="button"
    class="toggle-button"
    :class="{ active }"
    role="switch"
    :aria-checked="active.toString()"
    @click="onClick"
  >
    <span aria-hidden="true" :class="{ active }"></span>
  </button>
</template>

<script>
export default {
  props: {
    active: { type: Boolean, default: false },
  },

  methods: {
    onClick(e) {
      this.$emit('click', e);
    },
  },
};
</script>
<style lang="scss" scoped>
.toggle-button {
  background-color: var(--s-200);
  position: relative;
  display: inline-flex;
  height: 19px;
  width: 34px;
  border: 2px solid transparent;
  border-radius: var(--border-radius-large);
  cursor: pointer;
  transition-property: background-color;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 200ms;
  flex-shrink: 0;
}

.toggle-button.active {
  background-color: var(--w-500);
}

.toggle-button span {
  --space-one-point-five: 1.5rem;
  height: var(--space-one-point-five);
  width: var(--space-one-point-five);
  display: inline-block;
  background-color: var(--white);
  box-shadow: rgb(255, 255, 255) 0px 0px 0px 0px,
    rgba(59, 130, 246, 0.5) 0px 0px 0px 0px, rgba(0, 0, 0, 0.1) 0px 1px 3px 0px,
    rgba(0, 0, 0, 0.06) 0px 1px 2px 0px;
  transform: translate(0, 0);
  border-radius: 100%;
  transition-property: transform;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 200ms;
}
.toggle-button span.active {
  transform: translate(var(--space-one-point-five), var(--space-zero));
}
</style>
