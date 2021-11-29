<template>
  <i class="ion-android-menu hamburger--menu" @click="onMenuItemClick" />
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
<style lang="scss" scoped>
.ion-android-menu {
  font-size: var(--font-size-big);
}
</style>
