<template>
  <i class="ion-android-menu hamburger--menu" @click="onMenuItemClick"></i>
</template>

<script>
/* global bus */
export default {
  methods: {
    onMenuItemClick() {
      bus.$emit('sidemenu_icon_click');
    },
  },
};
</script>
