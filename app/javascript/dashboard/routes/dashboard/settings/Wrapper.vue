<template>
  <div
    class="flex flex-1 h-full justify-between flex-col m-0 bg-slate-25 dark:bg-slate-900 overflow-auto"
  >
    <settings-header
      button-route="new"
      :icon="icon"
      :header-title="$t(headerTitle)"
      :button-text="$t(headerButtonText)"
      :show-back-button="showBackButton"
      :back-url="backUrl"
      :show-new-button="showNewButton"
      :show-sidemenu-icon="showSidemenuIcon"
    />
    <keep-alive v-if="keepAlive">
      <router-view />
    </keep-alive>
    <router-view v-else />
  </div>
</template>

<script>
/* eslint no-console: 0 */
import SettingsHeader from './SettingsHeader.vue';

export default {
  components: {
    SettingsHeader,
  },
  props: {
    headerTitle: { type: String, default: '' },
    headerButtonText: { type: String, default: '' },
    icon: { type: String, default: '' },
    keepAlive: {
      type: Boolean,
      default: true,
    },
    newButtonRoutes: {
      type: Array,
      default: () => [],
    },
    showBackButton: {
      type: Boolean,
      default: false,
    },
    backUrl: {
      type: [String, Object],
      default: '',
    },
    showSidemenuIcon: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return {};
  },
  computed: {
    currentPage() {
      return this.$store.state.route.name;
    },
    showNewButton() {
      return this.newButtonRoutes.length !== 0 && !this.showBackButton;
    },
  },
};
</script>
