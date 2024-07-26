<script>
export default {
  props: {
    status: { type: String, default: '' },
  },
};
</script>

<template>
  <div
    :class="`status-badge status-badge__${status} rounded-full w-2.5 h-2.5 mr-0.5 rtl:mr-0 rtl:ml-0.5 inline-flex`"
  />
</template>

<style lang="scss" scoped>
.status-badge {
  &__online {
    @apply bg-green-400;
  }
  &__offline {
    @apply bg-slate-500;
  }
  &__busy {
    @apply bg-yellow-500;
  }
}
</style>
