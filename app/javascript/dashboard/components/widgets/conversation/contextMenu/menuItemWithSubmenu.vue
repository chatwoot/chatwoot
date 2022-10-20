<template>
  <div
    class="menu-with-submenu flex-between"
    :class="{ disabled: !subMenuAvailable }"
  >
    <div class="menu-left">
      <fluent-icon :icon="option.icon" size="14" class="menu-icon" />
      <p class="menu-label">{{ option.label }}</p>
    </div>
    <fluent-icon icon="chevron-right" size="12" />
    <div v-if="subMenuAvailable" class="submenu">
      <slot />
    </div>
  </div>
</template>

<script>
export default {
  props: {
    option: {
      type: Object,
      default: () => {},
    },
    subMenuAvailable: {
      type: Boolean,
      default: true,
    },
  },
};
</script>

<style scoped lang="scss">
.menu-with-submenu {
  width: 100%;
  padding: var(--space-smaller);
  border-radius: var(--border-radius-small);
  position: relative;
  min-width: calc(var(--space-mega) * 2);
  background-color: var(--white);

  .menu-left {
    display: flex;
    align-items: center;

    .menu-label {
      margin: 0;
      font-size: var(--font-size-mini);
    }

    .menu-icon {
      margin-right: var(--space-small);
    }
  }

  .submenu {
    padding: var(--space-smaller);
    background-color: var(--white);
    box-shadow: var(--shadow-context-menu);
    border-radius: var(--border-radius-normal);
    position: absolute;
    position: absolute;
    left: 100%;
    top: 0;
    display: none;
    min-height: min-content;
    max-height: var(--space-giga);
    overflow-y: auto;
    // Need this because Firefox adds a horizontal scrollbar, if a text is truncated inside.
    overflow-x: hidden;
  }

  &:hover {
    background-color: var(--w-75);
    .submenu {
      display: block;
    }
    &:before {
      content: '';
      position: absolute;
      z-index: var(--z-index-highest);
      bottom: -65%;
      height: 75%;
      right: 0%;
      width: 50%;
      clip-path: polygon(100% 0, 0% 0%, 100% 100%);
    }
  }

  &.disabled {
    opacity: 50%;
    cursor: not-allowed;
  }
}
</style>
