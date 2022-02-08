<template>
  <div :class="`status-badge status-badge__${status}`" />
</template>
<script>
export default {
  props: {
    status: { type: String, default: '' },
  },
};
</script>
<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';
.status-badge {
  width: var(--space-one);
  height: var(--space-one);
  margin-right: var(--space-micro);
  display: inline-block;
  border-radius: 50%;
  &__online {
    background: var(--g-400);
  }
  &__offline {
    background: var(--s-500);
  }
  &__busy {
    background: var(--y-700);
  }
}
</style>
