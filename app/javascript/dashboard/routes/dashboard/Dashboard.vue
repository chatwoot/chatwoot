<template>
  <div class="row app-wrapper">
    <sidebar :route="currentRoute" :class="sidebarClassName"></sidebar>
    <section class="app-content columns" :class="contentClassName">
      <router-view></router-view>
      <command-bar />
    </section>
  </div>
</template>

<script>
import Sidebar from '../../components/layout/Sidebar';
import CommandBar from './commands/commandbar.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';

export default {
  components: {
    Sidebar,
    CommandBar,
  },
  data() {
    return {
      isSidebarOpen: false,
      isOnDesktop: true,
    };
  },
  computed: {
    currentRoute() {
      return ' ';
    },
    sidebarClassName() {
      if (this.isOnDesktop) {
        return '';
      }
      if (this.isSidebarOpen) {
        return 'off-canvas is-open ';
      }
      return 'off-canvas position-left is-transition-push is-closed';
    },
    contentClassName() {
      if (this.isOnDesktop) {
        return '';
      }
      if (this.isSidebarOpen) {
        return 'off-canvas-content is-open-left has-transition-push has-position-left';
      }
      return 'off-canvas-content';
    },
  },
  mounted() {
    this.$store.dispatch('setCurrentAccountId', this.$route.params.accountId);
    window.addEventListener('resize', this.handleResize);
    this.handleResize();
    bus.$on(BUS_EVENTS.TOGGLE_SIDEMENU, this.toggleSidebar);
  },
  beforeDestroy() {
    bus.$off(BUS_EVENTS.TOGGLE_SIDEMENU, this.toggleSidebar);
    window.removeEventListener('resize', this.handleResize);
  },
  methods: {
    handleResize() {
      if (window.innerWidth > 1200) {
        this.isOnDesktop = true;
      } else {
        this.isOnDesktop = false;
      }
    },
    toggleSidebar() {
      this.isSidebarOpen = !this.isSidebarOpen;
    },
  },
};
</script>
