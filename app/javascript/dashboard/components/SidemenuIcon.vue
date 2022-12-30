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
  margin-right: var(--space-small);
  margin-left: var(--space-minus-small);
}
</style>
