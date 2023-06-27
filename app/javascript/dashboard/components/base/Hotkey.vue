<template>
  <kbd class="hotkey">
    <slot />
  </kbd>
</template>

<style lang="scss">
kbd.hotkey {
  display: inline-flex;
  flex-shrink: 0;
  align-items: center;
  user-select: none;
  justify-content: center;
  padding: var(--space-micro);
  min-width: var(--space-normal);
  font-size: var(--font-size-micro);
  border-radius: var(--space-smaller);
  background-color: var(--color-background);
  border: 1px solid var(--color-border);
  text-transform: uppercase;
  color: var(--color-body);
  letter-spacing: var(--space-micro);
  line-height: var(--font-size-micro);
}
</style>
