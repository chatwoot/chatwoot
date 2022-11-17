<template>
  <div>
    <button
      v-tooltip="tooltip"
      class="macros__action-button"
      :class="type"
      @click="$emit('click')"
    >
      <fluent-icon :icon="icon" aria-hidden="true" />
    </button>
  </div>
</template>

<script>
export default {
  props: {
    type: {
      type: String,
      default: 'add',
    },
    tooltip: {
      type: String,
      default: '',
    },
    icon: {
      type: String,
      required: true,
    },
  },
};
</script>

<style scoped lang="scss">
.macros__action-button {
  height: var(--space-three);
  width: var(--space-three);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: var(--font-size-default);
  border-radius: var(--border-radius-rounded);
  position: relative;
  margin-left: var(--space-one);

  &.add {
    background-color: var(--g-100);
    color: var(--g-600);
  }
  &.delete {
    position: absolute;
    top: calc(var(--space-three) / -2);
    right: calc(var(--space-three) / -2);
    background-color: var(--r-100);
    color: var(--r-600);
  }
}
</style>
