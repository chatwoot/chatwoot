<template>
  <div class="column page-top-banner">
    <h2 class="page-sub-title">
      {{ headerTitle }}
    </h2>
    <p v-if="headerContent" class="small-12 column">
      {{ headerContent }}
    </p>
    <slot />
  </div>
</template>

<script>
export default {
  props: {
    headerTitle: {
      type: String,
      default: '',
    },
    headerContent: {
      type: String,
      default: '',
    },
  },
};
</script>
<style lang="scss" scoped>
.page-top-banner {
  border-bottom: 1px solid var(--color-border-light);
  background: var(--s-25);
  padding: var(--space-normal) var(--space-large) 0;
}
</style>
