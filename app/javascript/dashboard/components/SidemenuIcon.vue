<template>
  <woot-button
    size="small"
    variant="clear"
    color-scheme="secondary"
    icon="list"
    class="toggle-sidebar"
    @click="onMenuItemClick"
  />
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
.toggle-sidebar {
  margin-left: var(--space-minus-small);
}

.app-rtl--wrapper {
  .toggle-sidebar {
    margin-left: 0;
    margin-right: var(--space-minus-small);
    transform: rotate(180deg);
  }
}
</style>
