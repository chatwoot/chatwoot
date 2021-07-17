<template>
  <div class="footer-wrap">
    <div class="input-area"></div>
  </div>
</template>

<script>
export default {
  name: 'WidgetFooter',
};
</script>

<style scoped lang="scss">
$tailwind-slate-50: #f4f6fb;
.footer-wrap {
  flex-shrink: 0;
  width: 100%;
  display: flex;
  flex-direction: column;
  position: relative;
  &::before {
    content: '';
    position: absolute;
    top: -1rem;
    left: 0;
    width: 100%;
    height: 1rem;
    opacity: 0.1;
    background: $tailwind-slate-50;
  }

  .input-area {
    background-color: var(--white);
    border-radius: var(--border-radius-normal);
    height: var(--space-larger);
    margin: var(--space-two);
  }
}
</style>
