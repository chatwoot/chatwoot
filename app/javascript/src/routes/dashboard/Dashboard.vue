<template>
  <div class="row app-wrapper">
    <sidebar :route="currentRoute"></sidebar>
    <router-view></router-view>
  </div>
</template>

<script>
/* eslint no-console: 0 */
import Sidebar from '../../components/layout/Sidebar';

export default {
  props: {
    mainViewComponent: String,
    sidebarMenu: String,
    page: String,
  },
  components: {
    Sidebar,
  },
  computed: {
    currentRoute() {
      return ' ';
    },
  },
};
</script>
