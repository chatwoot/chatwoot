<template>
  <div />
</template>

<script>
export default {
  mounted() {
    this.handler = event => {
      event.preventDefault();
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
