<template>
  <div class="footer-wrap">
    <div class="input-area" />
  </div>
</template>

<script>
export default {
  name: 'WidgetFooter',
};
</script>

<style scoped lang="scss">
.footer-wrap {
  flex-shrink: 0;
  width: 100%;
  display: flex;
  flex-direction: column;
  position: relative;
  &::before {
    content: '';
    position: absolute;
    top: var(--space-one);
    left: 0;
    width: 100%;
    height: var(--space-one);
    opacity: 0.1;
    background: var(--color-background);
  }

  .input-area {
    background-color: var(--white);
    border-radius: var(--border-radius-normal);
    height: var(--space-larger);
    margin: var(--space-two);
  }
}
</style>
