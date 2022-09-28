<template>
  <li class="dropdown-menu--divider" :tabindex="null" :aria-disabled="true" />
</template>
<script>
export default {};
</script>
<style lang="scss" scoped>
.dropdown-menu--divider {
  list-style: none;
  margin: var(--space-small) 0;
  border-bottom: 1px solid var(--s-50);
}
</style>
