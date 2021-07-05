<template>
  <i class="ion-android-menu hamburger--menu" @click="onMenuItemClick" />
</template>

<script>
export default {
  methods: {
    onMenuItemClick() {
      bus.$emit('sidemenu_icon_click');
    },
  },
};
</script>
<style lang="scss" scoped>
.ion-android-menu {
  font-size: var(--font-size-big);
}
</style>
