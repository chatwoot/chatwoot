<template>
  <div>
    <div class="macros-item macros-pill">
      <span>{{ label }}</span>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    label: {
      type: String,
      required: true,
    },
  },
};
</script>

<style scoped>
.macros-pill {
  padding: var(--space-slab);
  background-color: var(--w-500);
  max-width: max-content;
  color: var(--white);
  font-size: var(--font-size-small);
  border-radius: var(--border-radius-full);
  position: relative;
}
</style>
