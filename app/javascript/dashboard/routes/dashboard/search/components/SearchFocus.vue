<template>
  <div />
</template>

<script>
export default {
  mounted() {
    this.handler = event => {
      this.$emit('keyup', event);
    };
    window.addEventListener('keyup', this.handler);
  },
  beforeDestroy() {
    window.removeEventListener('keyup', this.handler);
  },
};
</script>
<style scoped>
div {
  display: none;
}
</style>
