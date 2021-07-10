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
    background: linear-gradient(to top, #f4f6fb, rgba(244, 246, 251, 0));
  }

  .input-area {
    background-color: #fff;
    border-radius: 4px;
    height: 40px;
    margin: 20px 20px 30px;
  }
}
</style>
