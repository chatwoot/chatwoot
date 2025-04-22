<script>
export default {
  props: {
    data: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      messageData: this.data,
    };
  },
};
</script>

<template>
  <div>
    CARD
  </div>
</template>

<style lang="scss">
</style>
