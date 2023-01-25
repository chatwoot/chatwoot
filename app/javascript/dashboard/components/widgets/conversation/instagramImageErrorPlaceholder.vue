<template>
  <div class="image-placeholder">
    <fluent-icon icon="document-error" size="32" />
    <p>Could not load instagram story</p>
  </div>
</template>

<script>
export default {};
</script>

<style scoped>
.image-placeholder {
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
  padding: var(--space-slab);
  height: calc(var(--space-large) * 10);
  margin-top: var(--space-one);
  width: 100%;
  background-color: var(--s-75);
  color: var(--s-800);
  border-radius: var(--border-radius-normal);
}
</style>
