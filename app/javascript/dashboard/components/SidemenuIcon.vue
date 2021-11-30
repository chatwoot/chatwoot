<template>
  <button @click="onMenuItemClick">
    <fluent-icon class="hamburger--menu" icon="list" />
  </button>
</template>

<script>
import { BUS_EVENTS } from 'shared/constants/busEvents';

export default {
  methods: {
    onMenuItemClick() {
      bus.$emit(BUS_EVENTS.TOGGLE_SIDEMENU);
    },
  },
};
</script>
<style scoped lang="scss">
.hamburger--menu {
  cursor: pointer;
  display: none;
  margin-right: var(--space-normal);

  @media screen and (max-width: 1200px) {
    display: block;
  }
}
</style>
